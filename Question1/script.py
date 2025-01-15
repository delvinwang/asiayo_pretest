import re
from collections import Counter


def find_most_common_word(filename):
    # Read the file
    with open(filename, "r") as file:
        # Convert all words in file to lowercase since it is case insensitive
        text = file.read().lower()

    # Split into words and remove punctuation
    words = re.findall(r"\b\w+\b", text)

    # Count word frequencies
    word_counts = Counter(words)

    # Find the most common word
    most_common_word = word_counts.most_common(1)[0]

    return most_common_word


# If the text is in a file named 'words.txt'
most_common = find_most_common_word("./words.txt")
print(most_common[1], most_common[0])
