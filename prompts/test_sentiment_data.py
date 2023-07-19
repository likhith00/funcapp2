import pytest
from classification import test_sentiment_classificationapp

# Data testing
@pytest.mark.parametrize("input_text", [
    "Today was a fantastic day at the beach. The weather was perfect, and I had a great time with my friends.",
    "I am feeling really down today. Nothing seems to be going my way, and it's just one of those days.",
    "",
    None,
    123,
    [],
])
def test_data_validation(input_text):
    with pytest.raises(ValueError):
        test_sentiment_classificationapp(input_text)
