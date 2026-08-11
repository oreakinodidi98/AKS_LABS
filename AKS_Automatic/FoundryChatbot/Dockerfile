FROM python:3.11-slim
ENV PORT=8080
EXPOSE 8080
WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT ["streamlit", "run", "chatbot.py", "--server.address=0.0.0.0"]
CMD ["--server.port=8080"]