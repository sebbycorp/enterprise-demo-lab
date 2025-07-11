FROM python:3.11-slim

# Install system dependencies required for Ansible
RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create directories for playbooks and app
RUN mkdir -p /app/playbooks /app/logs

# Copy application files
COPY . .

# Create ansible.cfg for better defaults
RUN mkdir -p /etc/ansible && \
    echo "[defaults]" > /etc/ansible/ansible.cfg && \
    echo "host_key_checking = False" >> /etc/ansible/ansible.cfg && \
    echo "stdout_callback = yaml" >> /etc/ansible/ansible.cfg && \
    echo "log_path = /app/logs/ansible.log" >> /etc/ansible/ansible.cfg

# Expose Streamlit port
EXPOSE 8501

# Set environment variables
ENV STREAMLIT_SERVER_HEADLESS=true
ENV STREAMLIT_SERVER_ENABLE_CORS=false
ENV STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION=false

# Run Streamlit app
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"] 