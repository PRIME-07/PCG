# OCR + LLM Extraction API

A FastAPI-based backend for extracting structured information from scanned documents (PDFs or images) using OCR and Large Language Model (LLM) post-processing.

## Features
- **OCR Extraction**: Converts images or PDFs to text using a vision-language model.
- **LLM Extraction**: Parses OCR text into structured JSON (entities, tables, form fields, document structure).
- **Full Pipeline**: Upload a file and get both OCR and structured JSON in one call.
- **Robust error handling** and input validation.
- **Easy-to-use REST API** with interactive docs (Swagger UI).

## Setup Instructions

### 1. Clone the Repository
```
git clone <your-repo-url>
cd <your-repo-root>
```

### 2. Install Dependencies
Make sure you have Python 3.8+ and pip installed.

**Install all dependencies:**
```
pip install -r requirements.txt
```
- You may need additional dependencies for your OCR/LLM models (see your model's requirements).

### 3. Model Weights
- Ensure the required model weights for OCR and LLM are available or will be downloaded on first run.
- The code expects the model to be accessible as in `ocr.py` and `inference.py`.

### 4. Run the API Server
From the directory containing `api.py` (e.g., `src/olmocr_core/core/`):

```
uvicorn api:app --reload
```

Or from the project root:
```
uvicorn src.olmocr_core.core.api:app --reload
```

Visit [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) for the interactive API docs.

---

## API Endpoints

### 1. `/ocr-extract` (POST)
**Description:** Upload a PDF or image, get OCR text.

**Request:**
- `file`: File upload (PDF, JPG, PNG, JPEG)
- `page_num`: (optional, default=1) For PDFs, which page to process

**Response:**
```json
{
  "ocr_text": "..."
}
```

**Example (curl):**
```sh
curl -X POST "http://127.0.0.1:8000/ocr-extract" -F "file=@yourfile.pdf" -F "page_num=1"
```

---

### 2. `/llm-extract` (POST)
**Description:** Submit OCR text, get structured JSON extraction.

**Request (JSON):**
```json
{
  "ocr_text": "..."
}
```

**Response:**
```json
{
  "parsed_json": { /* structured extraction */ }
}
```

**Example (curl):**
```sh
curl -X POST "http://127.0.0.1:8000/llm-extract" -H "Content-Type: application/json" -d "{\"ocr_text\": \"...\"}"
```

---

### 3. `/full-pipeline` (POST)
**Description:** Upload a file, get both OCR text and structured JSON in one call.

**Request:**
- `file`: File upload (PDF, JPG, PNG, JPEG)
- `page_num`: (optional, default=1)

**Response:**
```json
{
  "ocr_text": "...",
  "parsed_json": { /* structured extraction */ }
}
```

**Example (curl):**
```sh
curl -X POST "http://127.0.0.1:8000/full-pipeline" -F "file=@yourfile.pdf" -F "page_num=1"
```

---

## Notes
- **Supported file types:** PDF, JPG, JPEG, PNG
- **Error handling:** Returns HTTP 400 for invalid input, 500 for internal errors (with details).
- **Customization:**
  - You can swap out the OCR or LLM model by editing `ocr.py` and `inference.py`.
  - Adjust prompt templates or output formats as needed.
- **Security:** This API does not implement authentication. Add as needed for production.

---
