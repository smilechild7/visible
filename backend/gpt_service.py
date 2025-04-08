# GPT-4o Vision 호출 모듈
import openai
import base64
import os
from dotenv import load_dotenv

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")  # .env에 API 키 넣기

async def analyze_image_and_question(image_base64: str, question: str) -> str:
    image_url = f"data:image/jpeg;base64,{image_base64}"

    messages = [
        {"role": "system", "content": "당신은 시각장애인을 위한 편의점 상품 안내 도우미입니다. 핵심 정보만 짧고 간결하게 제공하세요."},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": question},
                {"type": "image_url", "image_url": {"url": image_url}}
            ]
        }
    ]

    response = openai.ChatCompletion.create(
        model="gpt-4o",
        messages=messages,
        max_tokens=300
    )

    return response.choices[0].message['content']
