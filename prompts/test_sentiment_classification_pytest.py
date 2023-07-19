import pytest
from classification import test_sentiment_classificationapp

# Test cases
@pytest.mark.parametrize("input_text, expected_sentiment", [
    ("Today was a fantastic day at the beach. The weather was perfect, and I had a great time with my friends.", "Positive"),
    ("I am feeling really down today. Nothing seems to be going my way, and it's just one of those days.", "Negative"),
    ("I'm not sure how I feel about this.", "Unknown"),
])
def test_sentiment_classification(input_text, expected_sentiment):
    result_sentiment = test_sentiment_classificationapp(input_text)
    assert result_sentiment.lower() == expected_sentiment.lower()
