# Wan2GP Launcher (UV)

**Portable, self-contained installer and launcher for Wan2GP on Windows.**

> This launcher uses **UV** — a fast, lightweight Python package manager — to create an isolated environment. No system‑wide Python or Conda installation is required. Everything stays inside the project folder.

---

## English

### Features

- **One‑click setup** – downloads UV, creates a virtual environment, installs PyTorch and all dependencies automatically.
- **GPU‑aware installation** – choose between GTX 10xx (CUDA 12.8) and RTX 20xx‑50xx (CUDA 13.1).
- **All optional accelerators** – SageAttention, FlashAttention, SpargeAttention, GGUF kernels, Nunchaku, Bitsandbytes, Triton – are installed automatically.
- **Interactive launch menu** – quickly switch between modes:
  - Basic GUI (model dropdown)
  - Image‑to‑Video (`--i2v`)
  - T2V 1.3B (`--t2v-1-3B`) – fast
  - T2V 14B (`--t2v-14B`) – high quality
- **Automatic port allocation** – if port 7860 is busy, the launcher finds the next free port.
- **Fully portable** – all caches, virtual environment, and UV binaries reside inside the script’s folder. Move the folder anywhere and it still works.
- **Always uses `--listen --share`** – enables remote access and creates a public Gradio link when needed.

---

### Requirements

- Windows 7 / 10 / 11 (x64)
- [Git](https://git-scm.com/download/win) installed and available in `PATH`
- Internet connection (to download UV, Wan2GP, and Python packages)
- NVIDIA GPU with appropriate drivers (CUDA 12.8 or 13.1)

> The launcher does **not** require administrator privileges.

---

### Installation & Usage

1. **Download** the script `Wan2GP-Launcher.ps1` into an empty folder.
2. **Right‑click** the file and select **“Run with PowerShell”** – or open a PowerShell window in that folder and run:
   
   ```powershell
   .\Wan2GP-Launcher.ps1
   ```
3. **First run** will automatically:
   - Download UV (≈10 MB).
   - Clone the Wan2GP repository.
   - Create a Python virtual environment.
   - Install PyTorch (choose your GPU type).
   - Install all dependencies and accelerators.
4. After installation, the **launch menu** appears – select the desired mode.
5. The application opens in your browser (or shows a Gradio share link if localhost is not accessible).

---

### Launch Modes

| Option          | Description                                        |
| --------------- | -------------------------------------------------- |
| **1. Basic**    | Standard GUI – choose any model from the dropdown. |
| **2. I2V**      | Image‑to‑Video mode (`--i2v`).                     |
| **3. T2V 1.3B** | Faster text‑to‑video model (`--t2v-1-3B`).         |
| **4. T2V 14B**  | Larger, higher‑quality model (`--t2v-14B`).        |
| **5. Exit**     | Close the launcher.                                |

---

### How It Works

- The script first checks for Git and downloads `uv.exe` into `Bin\`.
- It creates a Python virtual environment in `Wan2GP\env\`.
- It installs PyTorch with the selected CUDA version.
- It processes `requirements.txt` (with additional PyPI indexes for `onnxruntime-gpu`).
- It installs all accelerator wheels from pre‑defined URLs.
- It then presents the launch menu.
- On each launch, it searches for a free port (starting from 7860) and passes `--server-port` to Wan2GP.

---

### Folder Structure (after installation)

```
.
├── Bin\                 # UV executables
├── Wan2GP\              # Cloned Wan2GP repository
│   ├── env\             # Python virtual environment
│   └── wgp.py           # Main application
├── .wan2gp_config       # Saved GPU configuration (auto‑created)
└── Wan2GP-Launcher.ps1  # This script
```

All cache files (`uv`, `pip`, Hugging Face) are stored inside the script’s folder – no writes to `%USERPROFILE%`.

---

### Troubleshooting

- **Port already in use** – the launcher automatically tries the next port (7861, 7862, …).
- **`onnxruntime-gpu` installation error** – the script uses `--index-strategy unsafe-best-match` and the correct extra index, so it should resolve correctly.
- **Git not found** – install Git and make sure it’s in your `PATH`.
- **Permission denied** – run the script as a normal user; no admin rights are needed.




