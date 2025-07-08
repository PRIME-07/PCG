'''
Instructions to run code:

# To run the FastAPI server from the src directory:
    "python -m olmocr_core.core.api"

# Or with uvicorn (from src):
    "uvicorn olmocr_core.core.api:app --host 0.0.0.0 --port 8000 --workers 1"
'''

import os
from pathlib import Path
from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import tempfile
from typing import List, Dict, Any
from olmocr_core.core.ocr import run_ocr, call_ollama_entities_extraction, call_ollama_table_extraction, is_pdf_file, is_image_file, run_olmocr_ocr
import requests
import json
from functools import lru_cache

"""
FastAPI endpoints for OCR+LLM extraction.
- Model and processor are loaded once at module level (see ocr.py).
- Always run with a single uvicorn worker for large models:
    uvicorn olmocr_core.core.api:app --host 0.0.0.0 --port 8000 --workers 1
- Ollama HTTP session is reused for all requests.
- Batch endpoint processes files sequentially to avoid model reloads.
"""

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Reuse a single requests.Session for Ollama
ollama_session = requests.Session()

def call_ollama_entities_extraction_with_session(ocr_text: str, session: requests.Session) -> dict:
    from olmocr_core.core.ocr import call_ollama_entities_extraction
    # Patch the function to use the provided session
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
        response = session.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
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

def call_ollama_table_extraction_with_session(ocr_text: str, session: requests.Session) -> list:
    from olmocr_core.core.ocr import call_ollama_table_extraction
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
        response = session.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
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

class ExtractionResult(BaseModel):
    entities: dict
    tables: list
    form_fields: Dict[str, Any] = {}
    structure: Dict[str, Any] = {}

class ExtractionError(BaseModel):
    detail: str

def call_ollama_form_fields_extraction_with_session(ocr_text: str, session: requests.Session) -> dict:
    OLLAMA_BASE_URL = "http://localhost:11434"
    OLLAMA_MODEL = "qwen2.5vl:7b"
    prompt = f"""
You are an expert at extracting form fields from documents. Extract all form fields and their values as key-value pairs from the text below. Return ONLY valid JSON in this format:
{{
    "form_fields": {{
        "Field Name 1": "Value 1",
        "Field Name 2": "Value 2",
        ...
    }}
}}

Rules:
- Extract all field-value pairs, even if the value is blank or a checkbox (e.g., "Gender: Male", "Signature: [signed]", "Agree: Yes").
- Recognize fields in various layouts: "Field: Value", grid/table, checkboxes, etc.
- If a field is present but not filled, use an empty string as the value.
- If no form fields are found, return an empty object.
- Return ONLY the JSON, no explanations or extra text.

Examples:
---
Text: "Name: John Doe\nGender: Male\nAddress: 123 Main Street, Mumbai\nPhone: +91-98765-43210\nSignature: [signed]"
Output:
{{
    "form_fields": {{
        "Name": "John Doe",
        "Gender": "Male",
        "Address": "123 Main Street, Mumbai",
        "Phone": "+91-98765-43210",
        "Signature": "[signed]"
    }}
}}
---
Text: "Applicant: Jane Smith\nEmail: jane@example.com\nCheckbox: [X] Yes  [ ] No"
Output:
{{
    "form_fields": {{
        "Applicant": "Jane Smith",
        "Email": "jane@example.com",
        "Checkbox": "Yes"
    }}
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
        response = session.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
        response.raise_for_status()
        result = response.json()
        content = result["message"]["content"] if "message" in result else result.get("response", "")
        content = content.strip()
        if content.startswith('```json'):
            content = content[7:]
        if content.endswith('```'):
            content = content[:-3]
        content = content.strip()
        parsed = json.loads(content)
        return parsed.get("form_fields", {})
    except Exception as e:
        print(f"Error calling Ollama API for form fields: {e}")
        return {}

def call_ollama_structure_extraction_with_session(ocr_text: str, session: requests.Session) -> dict:
    OLLAMA_BASE_URL = "http://localhost:11434"
    OLLAMA_MODEL = "qwen2.5vl:7b"
    prompt = f"""
You are an expert at extracting document structure and hierarchy. Analyze the text and extract the structure as JSON. Return ONLY valid JSON in this format:
{{
    "sections": [
        {{
            "heading": "Section or Heading Title",
            "content": "Paragraph or section content as a single string.",
            "table": {{ ... }}  // if a table is present in this section
        }},
        ...
    ],
    "lists": [
        ["Bullet or numbered list item 1", "item 2", ...],
        ...
    ],
    "page_info": {{
        "page_number": 1,
        "header": "...",
        "footer": "..."
    }}
}}

Rules:
- Identify headings, subheadings, and section titles (e.g., "1. Introduction", "Section 2: Details").
- Group paragraphs under their respective headings.
- Extract tables as nested JSON if present in a section.
- Extract bullet points and numbered lists as arrays.
- Extract page number, header, and footer if present.
- If no structure is found, return empty arrays/objects.
- Return ONLY the JSON, no explanations or extra text.

Examples:
---
Text: "1. Introduction\nThis document outlines...\n2. Order Details\n| Item | Price |\n|---|---|\nBook | $10\nPen | $2\n3. Notes\n- Please deliver on time.\n- Contact for queries."
Output:
{{
    "sections": [
        {{"heading": "1. Introduction", "content": "This document outlines..."}},
        {{"heading": "2. Order Details", "table": {{"headers": ["Item", "Price"], "rows": [["Book", "$10"], ["Pen", "$2"]]}}}},
        {{"heading": "3. Notes", "content": "", "table": null}}
    ],
    "lists": [["Please deliver on time.", "Contact for queries."]],
    "page_info": {{"page_number": 1, "header": "", "footer": ""}}
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
            "num_predict": 1000
        }
    }
    try:
        response = session.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
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
        print(f"Error calling Ollama API for structure: {e}")
        return {}

def extract_relevant_json_for_llm(olmocr_json, field):
    # Helper to extract the relevant part of the OlmOCR JSON for LLM extraction
    # For now, just use the 'text' field, but can be extended for more structure
    if field == "text":
        return olmocr_json.get("text", "")
    return olmocr_json.get(field, "")

# Dependency to run OlmOCR once per request
async def get_olmocr_json(file: UploadFile = File(...)):
    suffix = Path(file.filename).suffix.lower()
    if not (is_pdf_file(file.filename) or is_image_file(file.filename)):
        raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or image file.")
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        temp_path = tmp.name
        content = await file.read()
        tmp.write(content)
    try:
        olmocr_json = run_olmocr_ocr(temp_path)
        return olmocr_json
    finally:
        try:
            os.remove(temp_path)
        except Exception:
            pass

@app.post("/extract", response_model=ExtractionResult, responses={400: {"model": ExtractionError}, 500: {"model": ExtractionError}})
async def extract_entities_from_file(file: UploadFile = File(...)):
    # Save uploaded file to a temp location
    try:
        suffix = Path(file.filename).suffix.lower()
        if not (is_pdf_file(file.filename) or is_image_file(file.filename)):
            raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or image file.")
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            content = await file.read()
            tmp.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save uploaded file: {e}")

    try:
        ocr_text = run_ocr(temp_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR failed: {e}")

    try:
        entities = call_ollama_entities_extraction_with_session(ocr_text, ollama_session)
        tables = call_ollama_table_extraction_with_session(ocr_text, ollama_session)
        form_fields = call_ollama_form_fields_extraction_with_session(ocr_text, ollama_session)
        structure = call_ollama_structure_extraction_with_session(ocr_text, ollama_session)
        output = {"entities": entities, "tables": tables, "form_fields": form_fields, "structure": structure}
        return output
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Extraction failed: {e}")
    finally:
        try:
            os.remove(temp_path)
        except Exception:
            pass

@app.post("/batch_extract", response_model=List[ExtractionResult], responses={400: {"model": ExtractionError}, 500: {"model": ExtractionError}})
async def batch_extract(files: List[UploadFile] = File(...)):
    results = []
    for file in files:
        try:
            suffix = Path(file.filename).suffix.lower()
            if not (is_pdf_file(file.filename) or is_image_file(file.filename)):
                results.append({"entities": {}, "tables": [], "form_fields": {}, "structure": {}, "error": f"Unsupported file type: {file.filename}"})
                continue
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                temp_path = tmp.name
                content = await file.read()
                tmp.write(content)
            ocr_text = run_ocr(temp_path)
            entities = call_ollama_entities_extraction_with_session(ocr_text, ollama_session)
            tables = call_ollama_table_extraction_with_session(ocr_text, ollama_session)
            form_fields = call_ollama_form_fields_extraction_with_session(ocr_text, ollama_session)
            structure = call_ollama_structure_extraction_with_session(ocr_text, ollama_session)
            results.append({"entities": entities, "tables": tables, "form_fields": form_fields, "structure": structure})
        except Exception as e:
            results.append({"entities": {}, "tables": [], "form_fields": {}, "structure": {}, "error": str(e)})
        finally:
            try:
                os.remove(temp_path)
            except Exception:
                pass
    return results

@app.post("/extract_form_fields", response_model=dict, responses={400: {"model": ExtractionError}, 500: {"model": ExtractionError}})
async def extract_form_fields_from_file(file: UploadFile = File(...)):
    try:
        suffix = Path(file.filename).suffix.lower()
        if not (is_pdf_file(file.filename) or is_image_file(file.filename)):
            raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or image file.")
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            content = await file.read()
            tmp.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save uploaded file: {e}")
    try:
        ocr_text = run_ocr(temp_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR failed: {e}")
    try:
        form_fields = call_ollama_form_fields_extraction_with_session(ocr_text, ollama_session)
        return {"form_fields": form_fields}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Form field extraction failed: {e}")
    finally:
        try:
            os.remove(temp_path)
        except Exception:
            pass

@app.post("/extract_structure", response_model=dict, responses={400: {"model": ExtractionError}, 500: {"model": ExtractionError}})
async def extract_structure_from_file(file: UploadFile = File(...)):
    try:
        suffix = Path(file.filename).suffix.lower()
        if not (is_pdf_file(file.filename) or is_image_file(file.filename)):
            raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or image file.")
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            content = await file.read()
            tmp.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save uploaded file: {e}")
    try:
        ocr_text = run_ocr(temp_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR failed: {e}")
    try:
        structure = call_ollama_structure_extraction_with_session(ocr_text, ollama_session)
        return {"structure": structure}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Structure extraction failed: {e}")
    finally:
        try:
            os.remove(temp_path)
        except Exception:
            pass

OLMOCR_JSON_PATH = "olmocr_output.json"

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    suffix = Path(file.filename).suffix.lower()
    if not (is_pdf_file(file.filename) or is_image_file(file.filename)):
        raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or image file.")
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        temp_path = tmp.name
        content = await file.read()
        tmp.write(content)
    try:
        olmocr_json = run_olmocr_ocr(temp_path)
        with open(OLMOCR_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(olmocr_json, f, ensure_ascii=False, indent=2)
        return {"message": "File processed and OlmOCR output saved."}
    finally:
        try:
            os.remove(temp_path)
        except Exception:
            pass

def load_olmocr_json_from_disk():
    try:
        with open(OLMOCR_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"No OlmOCR output found. Please upload a file first. ({e})")

@app.post("/extract_names", response_model=dict)
async def extract_names():
    olmocr_json = load_olmocr_json_from_disk()
    text_json = extract_relevant_json_for_llm(olmocr_json, "text")
    # Prompt LLM to extract names from JSON
    prompt = f"""
You are an expert at extracting person names from OCR JSON. Extract all person names from the following JSON. Return ONLY valid JSON in this format:
{{"names": ["Name1", "Name2", ...]}}
Input JSON:
{text_json}
Output:
"""
    messages = [
        {"role": "user", "content": prompt}
    ]
    payload = {
        "model": "qwen2.5vl:7b",
        "messages": messages,
        "stream": False,
        "options": {"temperature": 0.1, "num_predict": 300}
    }
    try:
        response = ollama_session.post("http://localhost:11434/api/chat", json=payload)
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
        raise HTTPException(status_code=500, detail=f"Name extraction failed: {e}")

@app.post("/extract_phones", response_model=dict)
async def extract_phones():
    olmocr_json = load_olmocr_json_from_disk()
    text_json = extract_relevant_json_for_llm(olmocr_json, "text")
    prompt = f"""
You are an expert at extracting phone numbers from OCR JSON. Extract all phone numbers from the following JSON. Return ONLY valid JSON in this format:
{{"phones": ["+91-98765-43210", ...]}}
Input JSON:
{text_json}
Output:
"""
    messages = [
        {"role": "user", "content": prompt}
    ]
    payload = {
        "model": "qwen2.5vl:7b",
        "messages": messages,
        "stream": False,
        "options": {"temperature": 0.1, "num_predict": 300}
    }
    try:
        response = ollama_session.post("http://localhost:11434/api/chat", json=payload)
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
        raise HTTPException(status_code=500, detail=f"Phone extraction failed: {e}")

@app.post("/extract_tables", response_model=dict)
async def extract_tables():
    olmocr_json = load_olmocr_json_from_disk()
    text_json = extract_relevant_json_for_llm(olmocr_json, "text")
    prompt = f"""
You are an expert at extracting tables from OCR JSON. Extract all tables from the following JSON. Return ONLY valid JSON in this format:
{{"tables": [{{"headers": [...], "rows": [...]}}]}}
Input JSON:
{text_json}
Output:
"""
    messages = [
        {"role": "user", "content": prompt}
    ]
    payload = {
        "model": "qwen2.5vl:7b",
        "messages": messages,
        "stream": False,
        "options": {"temperature": 0.1, "num_predict": 700}
    }
    try:
        response = ollama_session.post("http://localhost:11434/api/chat", json=payload)
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
        raise HTTPException(status_code=500, detail=f"Table extraction failed: {e}")
