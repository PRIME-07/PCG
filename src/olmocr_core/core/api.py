from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import shutil
import os
import tempfile
from ocr import run_ocr
from inference import run_llm_extraction
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Enable CORS (allow all origins)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LLMExtractRequest(BaseModel):
    ocr_text: str

class LLMExtractResponse(BaseModel):
    parsed_json: dict

class OCRExtractResponse(BaseModel):
    ocr_text: str

class FullPipelineResponse(BaseModel):
    ocr_text: str
    parsed_json: dict

@app.post("/ocr-extract", response_model=OCRExtractResponse)
def ocr_extract(file: UploadFile = File(...), page_num: int = 1):
    if not file.filename.lower().endswith((".pdf", ".jpg", ".jpeg", ".png")):
        raise HTTPException(status_code=400, detail="File must be a PDF or image.")
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            shutil.copyfileobj(file.file, temp_file)
            temp_path = temp_file.name
        ocr_output_path = temp_path + "_ocr.txt"
        run_ocr(temp_path, page_num=page_num, output_file=ocr_output_path)
        with open(ocr_output_path, "r", encoding="utf-8") as f:
            ocr_text = f.read()
        os.remove(temp_path)
        os.remove(ocr_output_path)
        return {"ocr_text": ocr_text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR extraction failed: {str(e)}")

@app.post("/llm-extract", response_model=LLMExtractResponse)
def llm_extract(request: LLMExtractRequest):
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".txt", mode="w", encoding="utf-8") as temp_ocr:
            temp_ocr.write(request.ocr_text)
            temp_ocr_path = temp_ocr.name
        temp_parsed_path = temp_ocr_path + "_parsed.json"
        run_llm_extraction(temp_ocr_path, temp_parsed_path)
        with open(temp_parsed_path, "r", encoding="utf-8") as f:
            import json
            parsed_json = json.load(f)
        os.remove(temp_ocr_path)
        os.remove(temp_parsed_path)
        return {"parsed_json": parsed_json}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM extraction failed: {str(e)}")

@app.post("/full-pipeline", response_model=FullPipelineResponse)
def full_pipeline(file: UploadFile = File(...), page_num: int = 1):
    if not file.filename.lower().endswith((".pdf", ".jpg", ".jpeg", ".png")):
        raise HTTPException(status_code=400, detail="File must be a PDF or image.")
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp_file:
            shutil.copyfileobj(file.file, temp_file)
            temp_path = temp_file.name
        ocr_output_path = temp_path + "_ocr.txt"
        parsed_output_path = temp_path + "_parsed.json"
        run_ocr(temp_path, page_num=page_num, output_file=ocr_output_path)
        with open(ocr_output_path, "r", encoding="utf-8") as f:
            ocr_text = f.read()
        run_llm_extraction(ocr_output_path, parsed_output_path)
        with open(parsed_output_path, "r", encoding="utf-8") as f:
            import json
            parsed_json = json.load(f)
        os.remove(temp_path)
        os.remove(ocr_output_path)
        os.remove(parsed_output_path)
        return {"ocr_text": ocr_text, "parsed_json": parsed_json}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Full pipeline failed: {str(e)}") 