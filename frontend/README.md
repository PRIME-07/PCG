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

# OCR Document Extractor (inside the kshitij-frontend branch)

A modern, dark-themed Flutter web application for extracting structured data from PDF documents and images using OCR technology and AI-powered data extraction.

## 🌟 Features

- **📄 Multi-format Support**: PDF, JPG, PNG, JPEG files
- **🔍 OCR Text Extraction**: Extract raw text from documents
- **🤖 AI-Powered Data Extraction**: Automatically identify entities (names, dates, emails, addresses, etc.)
- **📊 Table Detection**: Extract tables with headers and rows
- **🎨 Modern Dark UI**: Clean, minimalistic design with smooth animations
- **📱 Responsive**: Works seamlessly on desktop and mobile browsers
- **⚡ Real-time Processing**: Live pipeline visualization
- **🔄 Dynamic Data Display**: Handles any entity fields dynamically

## 🚀 Live Demo

The application features a visual processing pipeline that shows:
1. **Upload** - File selection and validation
2. **Process** - OCR extraction and AI analysis  
3. **Results** - Structured data display

## 🛠️ Tech Stack

- **Frontend**: Flutter Web
- **State Management**: Riverpod
- **HTTP Client**: Dart HTTP package
- **File Handling**: file_picker package
- **UI**: Material Design 3 with custom dark theme

## 📋 Prerequisites

- Flutter SDK (latest stable version)
- Chrome browser (for web development)
- Backend API server (see Backend Setup)

## 🔧 Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ocr-document-extractor.git
cd ocr-document-extractor
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Enable web support**
```bash
flutter config --enable-web
```

4. **Update API endpoint**
```dart
// In lib/providers/ocr_notifier.dart
static const String baseUrl = 'YOUR_API_ENDPOINT';
```

5. **Run the application**
```bash
flutter run -d chrome
```

## 🔌 Backend Setup

The frontend expects a backend API with the following endpoint:

### POST `/full-pipeline`
**Request:**
- `file`: Multipart file upload (PDF, JPG, PNG, JPEG)
- `page_num`: Optional page number for PDF processing (default: 1)

**Response:**
```json
{
  "ocr_text": "Extracted text content...",
  "parsed_json": {
    "entities": {
      "names": ["John Doe"],
      "dates": ["2025-01-15"],
      "emails": ["john@example.com"],
      "addresses": ["123 Main St"]
    },
    "tables": [
      {
        "headers": ["Item", "Price"],
        "rows": [["Book", "$10"], ["Pen", "$5"]]
      }
    ]
  }
}
```

### CORS Configuration
Add CORS middleware to your backend:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── ocr_state.dart       # State management model
├── providers/
│   └── ocr_notifier.dart    # Business logic & API calls
├── pages/
│   └── ocr_page.dart        # Main application page
└── widgets/
    ├── pipeline_card.dart   # Pipeline visualization
    ├── file_upload_card.dart # File upload interface
    └── result_card.dart     # Results display
```

## 🎨 UI Components

### Pipeline Visualization
- **Upload Node**: Shows file selection status
- **Process Node**: Displays processing state with loading animation
- **Results Node**: Indicates completion status

### File Upload
- Drag-and-drop interface
- File validation (type and size)
- Visual feedback for selected files

### Results Display
- **OCR Text**: Raw extracted text in monospace font
- **Entities**: Dynamic entity cards with icons
- **Tables**: Responsive table rendering with horizontal scroll

## 🔍 Dynamic Data Handling

The application automatically handles:
- **Unknown entity fields** (e.g., "age", "company", "salary")
- **Variable table structures** (any number of columns/rows)
- **Missing data** (graceful fallbacks)
- **Icon mapping** (smart icon selection based on field names)

## 🚀 Deployment

### Local Development
```bash
flutter run -d chrome
```

### Web Build
```bash
flutter build web
```

### GitHub Pages
1. Build the web version
2. Copy `build/web/` contents to your repository
3. Enable GitHub Pages in repository settings

## 🛠️ Development

### Adding New Features
1. Update state model in `ocr_state.dart`
2. Add business logic in `ocr_notifier.dart`
3. Create/update UI components in `widgets/`

### Customizing Theme
Update colors and styles in `main.dart`:
```dart
theme: ThemeData(
  scaffoldBackgroundColor: Color(0xFF0A0A0A),
  cardColor: Color(0xFF1A1A1A),
  primaryColor: Color(0xFF2196F3),
  // ... other theme properties
)
```

## 📱 Browser Support

- ✅ Chrome (recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Edge

## 🐛 Troubleshooting

### Common Issues

**CORS Error:**
- Ensure backend has CORS middleware enabled
- Check API endpoint URL

**File Upload Failed:**
- Verify file size (<50MB)
- Check supported formats (PDF, JPG, PNG, JPEG)
- Ensure backend is running

**422 Unprocessable Entity:**
- Check if `page_num` field is required
- Verify file format compatibility
- Check backend validation logs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for the design system
- OCR and AI technologies that power the backend

## 📞 Support

For questions or issues:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the API documentation

---

**Built with ❤️ using Flutter**
