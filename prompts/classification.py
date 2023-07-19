from transformers import pipeline



def test_sentiment_classificationapp(prompt_text):
    classifier = pipeline("sentiment-analysis")
    result = classifier(prompt_text)[0]

    label = result["label"]
    
    return label

# Example Input 1
'''input_text_1 = "Today was a fantastic day at the beach"
output_sentiment_1 = test_sentiment_classification(input_text_1)
print("Example 1 Sentiment:", output_sentiment_1)

# Example Input 2
input_text_2 = "I am feeling really down today"
output_sentiment_2 = test_sentiment_classification(input_text_2)
print("Example 2 Sentiment:", output_sentiment_2)'''