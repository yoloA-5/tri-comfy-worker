#!/usr/bin/env bash
set -euo pipefail

# 在每台 Codespace 内执行。
# 环境变量：
#   MODEL_URL       模型下载 URL（必填，建议 safetensors）
#   MODEL_FILENAME  保存文件名，例如 cyberrealistic.safetensors（必填，需和本地 .env 里的 CHECKPOINT 一致）
#   PORT            ComfyUI 端口，默认 8188

if [[ -z "${MODEL_URL:-}" || -z "${MODEL_FILENAME:-}" ]]; then
  echo "MODEL_URL 和 MODEL_FILENAME 必填" >&2
  exit 1
fi

PORT="${PORT:-8188}"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y git git-lfs python3-venv aria2

git lfs install
if [[ ! -d ComfyUI ]]; then
  git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ComfyUI
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip wheel
pip install -r requirements.txt

mkdir -p models/checkpoints
if [[ ! -f "models/checkpoints/${MODEL_FILENAME}" ]]; then
  echo "下载模型到 models/checkpoints/${MODEL_FILENAME}"
  aria2c -x 8 -s 8 -o "${MODEL_FILENAME}" -d models/checkpoints "${MODEL_URL}"
fi

cat > run-worker.sh <<EOF
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
source venv/bin/activate
python main.py --cpu --listen 0.0.0.0 --port ${PORT}
EOF
chmod +x run-worker.sh

echo "安装完成。启动：cd ComfyUI && ./run-worker.sh"
echo "然后在 Codespaces Ports 面板把 ${PORT} 转发/公开，复制 URL 到本地 .env。"
