import argparse
from ocr import run_ocr
from inference import run_llm_extraction

# User can set this variable to the desired file path
DEFAULT_TEST_FILE = "src/olmocr_core/test_ocr_files/book_order_letter.pdf"

def main():
    parser = argparse.ArgumentParser(description="Run OCR and LLM extraction on a document.")
    parser.add_argument("--input_file", default=DEFAULT_TEST_FILE, help="Path to input image or PDF file")
    parser.add_argument("--ocr_output", default="ocr_output.txt", help="File to save OCR output text")
    parser.add_argument("--parsed_output", default="parsed_output.json", help="File to save parsed LLM output")
    parser.add_argument("--page_num", type=int, default=1, help="Page number for PDF input (default: 1)")
    args = parser.parse_args()

    print(f"\nRunning OCR on {args.input_file}...")
    run_ocr(args.input_file, page_num=args.page_num, output_file=args.ocr_output)
    print(f"\nOCR output saved to {args.ocr_output}")

    print("\nRunning LLM extraction...")
    run_llm_extraction(args.ocr_output, args.parsed_output)
    print(f"\nParsed output saved to {args.parsed_output}")

if __name__ == "__main__":
    main() 