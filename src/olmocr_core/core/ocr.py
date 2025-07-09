import torch
import base64
import urllib.request
import os
from pathlib import Path

from io import BytesIO
from PIL import Image
from transformers import AutoProcessor, Qwen2VLForConditionalGeneration

from olmocr.data.renderpdf import render_pdf_to_base64png
from olmocr.prompts import build_finetuning_prompt
from olmocr.prompts.anchor import get_anchor_text
from olmocr.image_utils import convert_image_to_pdf_bytes

import sys
import json
import requests

# Initialize the model
model = Qwen2VLForConditionalGeneration.from_pretrained("allenai/olmOCR-7B-0225-preview", torch_dtype=torch.bfloat16).eval()
processor = AutoProcessor.from_pretrained("Qwen/Qwen2-VL-7B-Instruct")
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)


def is_pdf_file(file_path):
    """Check if the file is a PDF based on file extension and magic bytes."""
    file_path = Path(file_path)
    
    # Check file extension
    if file_path.suffix.lower() == '.pdf':
        return True
    
    # Check magic bytes for PDF
    try:
        with open(file_path, 'rb') as f:
            header = f.read(4)
            return header == b'%PDF'
    except Exception:
        return False


def is_image_file(file_path):
    """Check if the file is an image based on file extension and magic bytes (PNG, JPG, JPEG only)."""
    file_path = Path(file_path)
    
    # Check file extension
    image_extensions = {'.png', '.jpg', '.jpeg'}
    if file_path.suffix.lower() in image_extensions:
        return True
    
    # Check magic bytes for PNG, JPG, JPEG only
    try:
        with open(file_path, 'rb') as f:
            header = f.read(8)
            # PNG
            if header.startswith(b'\x89PNG\r\n\x1a\n'):
                return True
            # JPEG
            if header.startswith(b'\xff\xd8'):
                return True
    except Exception:
        pass
    
    return False


def process_image_file(image_path, target_longest_image_dim=1024):
    """Process an image file and return base64 encoded image and anchor text."""
    # Open and resize the image
    with Image.open(image_path) as img:
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize image while maintaining aspect ratio
        width, height = img.size
        if width > height:
            new_width = target_longest_image_dim
            new_height = int(height * target_longest_image_dim / width)
        else:
            new_height = target_longest_image_dim
            new_width = int(width * target_longest_image_dim / height)
        
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Convert to base64
        buffered = BytesIO()
        img.save(buffered, format="PNG")
        image_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")
    
    # For images, we create a simple anchor text with basic metadata
    # since we don't have PDF metadata
    anchor_text = f"Page dimensions: {width}.0x{height}.0\n[Image 0x0 to {new_width}x{new_height}]"
    
    return image_base64, anchor_text


def process_pdf_file(pdf_path, page_num=1, target_longest_image_dim=1024, target_anchor_text_len=4000):
    """Process a PDF file and return base64 encoded image and anchor text."""
    # Render page to an image
    image_base64 = render_pdf_to_base64png(pdf_path, page_num, target_longest_image_dim=target_longest_image_dim)
    
    # Build the prompt, using document metadata 
    anchor_text = get_anchor_text(pdf_path, page_num, pdf_engine="pdfreport", target_length=target_anchor_text_len)
    
    return image_base64, anchor_text


def process_file(file_path, page_num=1, target_longest_image_dim=1024, target_anchor_text_len=4000):
    """Process a file (PDF or image) and return base64 encoded image and anchor text."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    if is_pdf_file(file_path):
        return process_pdf_file(file_path, page_num, target_longest_image_dim, target_anchor_text_len)
    elif is_image_file(file_path):
        return process_image_file(file_path, target_longest_image_dim)
    else:
        raise ValueError(f"Unsupported file type: {file_path}")


def call_ollama_entities_extraction(ocr_text: str) -> dict:
    OLLAMA_BASE_URL = "http://localhost:11434"
    OLLAMA_MODEL = "qwen2.5vl:7b"
    prompt = f"""
You are an expert document parser. Extract the following entities from the provided text and return ONLY valid JSON in this format:
{{
    "names": ["list of person names found"],
    "dates": ["list of dates found in any format"],
    "addresses": ["list of complete addresses found (including street, city, state, postal code if present)"],
    "emails": ["list of email addresses found"]
}}

Rules:
- Only extract actual person names (not book titles, company names, etc.)
- Extract dates in all common formats, including but not limited to: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, Month DD, YYYY, DD Month YYYY, etc.
- Extract complete addresses, including street, city, state, and postal code if present.
- Extract all email addresses present in the text.
- Look for field labels such as: "Email", "E-mail", "Email Address", "Date", "Order Date", "Address", "Shipping Address", etc.
- If a value is present after a label (e.g., "Email: john@example.com"), extract the value.
- If no entities of a type are found, use empty array []
- Return ONLY the JSON, no explanations or additional text

Examples:
---
Text: "Order Date: 01/15/2023\nEmail: john@example.com\nAddress: 123 Main St, Springfield, IL 62704\nName: John Doe"
Output:
{{
    "names": ["John Doe"],
    "dates": ["01/15/2023"],
    "addresses": ["123 Main St, Springfield, IL 62704"],
    "emails": ["john@example.com"]
}}
---
Text: "To: Jane Smith <jane.smith@email.com>\nShipping Address: 456 Elm St, Apt 7B, New York, NY 10001\nDate: March 5, 2022"
Output:
{{
    "names": ["Jane Smith"],
    "dates": ["March 5, 2022"],
    "addresses": ["456 Elm St, Apt 7B, New York, NY 10001"],
    "emails": ["jane.smith@email.com"]
}}
---
Text: "Bill To: Dr. Alan Turing\nE-mail: alan.turing@computing.org\nAddress: 789 Binary Rd, Cambridge CB3 0FD, UK\nDate: 2023-07-10"
Output:
{{
    "names": ["Dr. Alan Turing"],
    "dates": ["2023-07-10"],
    "addresses": ["789 Binary Rd, Cambridge CB3 0FD, UK"],
    "emails": ["alan.turing@computing.org"]
}}
---
Text to analyze:
{ocr_text}
Output:
"""
    messages = [
        {"role": "user", "content": prompt}
    ]
    payload = {
        "model": OLLAMA_MODEL,
        "messages": messages,
        "stream": False,
        "options": {
            "temperature": 0.1,
            "num_predict": 700
        }
    }
    try:
        response = requests.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
        response.raise_for_status()
        result = response.json()
        content = result["message"]["content"] if "message" in result else result.get("response", "")
        content = content.strip()
        if content.startswith('```json'):
            content = content[7:]
        if content.endswith('```'):
            content = content[:-3]
        content = content.strip()
        return json.loads(content)
    except Exception as e:
        print(f"Error calling Ollama API for entities: {e}")
        return {"names": [], "dates": [], "addresses": [], "emails": []}


def call_ollama_table_extraction(ocr_text: str) -> list:
    OLLAMA_BASE_URL = "http://localhost:11434"
    OLLAMA_MODEL = "qwen2.5vl:7b"
    prompt = f"""
Please analyze the following text and extract the main table in JSON format. Return ONLY valid JSON, no other text.

Text to analyze:
{ocr_text}

Extract the first table and return it in this exact JSON format:
{{
    "headers": ["column1", "column2", "column3"],
    "rows": [
        ["row1_col1", "row1_col2", "row1_col3"],
        ["row2_col1", "row2_col2", "row2_col3"]
    ]
}}

Rules:
- Only extract the first table found in the text.
- If no table is found, return an empty list []
- Return ONLY the JSON, no explanations or additional text
"""
    messages = [
        {"role": "user", "content": prompt}
    ]
    payload = {
        "model": OLLAMA_MODEL,
        "messages": messages,
        "stream": False,
        "options": {
            "temperature": 0.1,
            "num_predict": 1000
        }
    }
    try:
        response = requests.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
        response.raise_for_status()
        result = response.json()
        content = result["message"]["content"] if "message" in result else result.get("response", "")
        content = content.strip()
        if content.startswith('```json'):
            content = content[7:]
        if content.endswith('```'):
            content = content[:-3]
        content = content.strip()
        if not content:
            return []
        # Try to parse as a dict (single table) or list (multiple tables)
        try:
            parsed = json.loads(content)
            if isinstance(parsed, dict):
                return [parsed]
            elif isinstance(parsed, list):
                return parsed
            else:
                return []
        except Exception:
            return []
    except Exception as e:
        print(f"Error calling Ollama API for tables: {e}")
        return []


def run_ocr(file_path, page_num=1, target_longest_image_dim=1024, target_anchor_text_len=4000, output_file=None):
    """Run OCR on a file (PDF or image) and save the result to output_file (required)."""
    if output_file is None:
        raise ValueError("output_file must be specified for run_ocr.")
    image_base64, anchor_text = process_file(file_path, page_num, target_longest_image_dim, target_anchor_text_len)
    prompt = build_finetuning_prompt(anchor_text)
    messages = [
        {
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{image_base64}"}},
            ],
        }
    ]
    text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    main_image = Image.open(BytesIO(base64.b64decode(image_base64)))
    inputs = processor(
        text=[text],
        images=[main_image],
        padding=True,
        return_tensors="pt",
    )
    inputs = {key: value.to(device) for (key, value) in inputs.items()}
    output = model.generate(
        **inputs,
        temperature=0.8,
        max_new_tokens=300,
        num_return_sequences=1,
        do_sample=True,
    )
    prompt_length = inputs["input_ids"].shape[1]
    new_tokens = output[:, prompt_length:]
    text_output = processor.tokenizer.batch_decode(
        new_tokens, skip_special_tokens=True
    )
    with open(output_file, "w", encoding="UTF-8") as f:
        f.write(text_output[0])
    # No return value


# Remove or comment out the __main__ block and any test file assignment, as this is now handled in main.py

