import requests
import json

def run_llm_extraction(ocr_output_file, parsed_output_file):
    OLLAMA_BASE_URL = "http://localhost:11434"
    OLLAMA_MODEL = "qwen2.5vl:7b"
    with open(ocr_output_file, "r", encoding="utf-8") as f:
        ocr_text = f.read()
    prompt = f"""
You are an expert document parser. Analyze the following OCR text and extract the following in valid JSON:

- Entities: Names, emails, phone numbers, dates, organizations, amounts, addresses
- Tables: Rows and columns of data in structured format
- Form Fields: Field-value pairs like "Name: John Doe", checkboxes
- Document Structure: Headings, paragraphs, bullet points, sectioned content

Format:
{{
  "entities": {{
    "names": [],
    "emails": [],
    "phone_numbers": [],
    "dates": [],
    "organizations": [],
    "amounts": [],
    "addresses": []
  }},
  "tables": [
    {{
      "headers": ["Book Title", "Author", "Price"],
      "rows": [
        ["1984", "George Orwell", "$10"],
        ["Brave New World", "Aldous Huxley", "$12"]
      ]
    }}
  ],
  "form_fields": {{
    "Name": "Anuj Kumar",
    "Gender": "Male",
    "Address": "123 Main Street, Mumbai",
    "Phone": "+91-98765-43210"
  }},
  "document_structure": {{
    "sections": [
      {{
        "heading": "1. Introduction",
        "content": "This document outlines..."
      }},
      {{
        "heading": "2. Order Details",
        "table": {{
          "headers": ["Book Title", "Price"],
          "rows": [["Deep Learning with Python", "$45"]]
        }}
      }}
    ]
  }},
  "full_text": "<all natural_text extracted by olmocr here>"
}}

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
            "num_predict": 1500
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
        with open(parsed_output_file, "w", encoding="utf-8") as f:
            f.write(content)
    except Exception as e:
        print(f"Error during inference: {e}") 