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
    """Check if the file is an image based on file extension and magic bytes."""
    file_path = Path(file_path)
    
    # Check file extension
    image_extensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff', '.tif', '.webp'}
    if file_path.suffix.lower() in image_extensions:
        return True
    
    # Check magic bytes for common image formats
    try:
        with open(file_path, 'rb') as f:
            header = f.read(8)
            # PNG
            if header.startswith(b'\x89PNG\r\n\x1a\n'):
                return True
            # JPEG
            if header.startswith(b'\xff\xd8'):
                return True
            # GIF
            if header.startswith(b'GIF87a') or header.startswith(b'GIF89a'):
                return True
            # BMP
            if header.startswith(b'BM'):
                return True
            # TIFF
            if header.startswith(b'II') or header.startswith(b'MM'):
                return True
            # WebP
            if header.startswith(b'RIFF') and header[8:12] == b'WEBP':
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


def run_ocr(file_path, page_num=1, target_longest_image_dim=1024, target_anchor_text_len=4000, output_file="model_output.txt"):
    """Run OCR on a file (PDF or image) and save the result."""
    # Process the file to get image and anchor text
    image_base64, anchor_text = process_file(file_path, page_num, target_longest_image_dim, target_anchor_text_len)
    
    # Build the prompt
    prompt = build_finetuning_prompt(anchor_text)
    
    # Build the full prompt
    messages = [
        {
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{image_base64}"}},
            ],
        }
    ]
    
    # Apply the chat template and processor
    text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    main_image = Image.open(BytesIO(base64.b64decode(image_base64)))
    
    inputs = processor(
        text=[text],
        images=[main_image],
        padding=True,
        return_tensors="pt",
    )
    inputs = {key: value.to(device) for (key, value) in inputs.items()}
    
    # Generate the output
    output = model.generate(
        **inputs,
        temperature=0.8,
        max_new_tokens=150,
        num_return_sequences=1,
        do_sample=True,
    )
    
    # Decode the output
    prompt_length = inputs["input_ids"].shape[1]
    new_tokens = output[:, prompt_length:]
    text_output = processor.tokenizer.batch_decode(
        new_tokens, skip_special_tokens=True
    )
    
    # Save response
    with open(output_file, "w", encoding="UTF-8") as f:
        f.write(text_output[0])
    
    # Print text output in console
    print(text_output[0])
    
    return text_output[0]


# Example usage
if __name__ == "__main__":
    # Insert test file path here
    test_file = "src/olmocr_core/test_ocr_files/ocr_demo_paper.png"
    
    # Run OCR on the file
    result = run_ocr(test_file)

