from transformers import pipeline

chef = pipeline(
    "text-generation",
    model="models/cecil_speaks",
    tokenizer="gpt2",
    config={"max_length": 0},
)

text = "166 - "
result = chef(text)[0]["generated_text"]

print(result)
