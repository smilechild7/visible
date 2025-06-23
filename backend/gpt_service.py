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
            "content": "당신은 시각장애인의 이동을 위한 도우미입니다. 사진 속에서 이동과 관련된 내용을 요약해줘.(계단, 장애물, 장소 등) 한국어로 설명하세요."
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
