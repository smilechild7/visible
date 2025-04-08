from openai import OpenAI
import os
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

async def analyze_image_and_question(image_base64: str, question: str) -> str:
    image_url = f"data:image/jpeg;base64,{image_base64}"

    messages = [
        {
            "role": "system",
            "content": "당신은 시각장애인을 위한 편의점 상품 안내 도우미입니다. 상품 이름, 가격, 유통기한, 할인정보를 간결하게, 한국어로 설명하세요."
        },
        {
            "role": "user",
            "content": [
                {"type": "text", "text": question},
                {"type": "image_url", "image_url": {"url": image_url}}
            ]
        }
    ]

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        max_tokens=300
    )

    return response.choices[0].message.content
