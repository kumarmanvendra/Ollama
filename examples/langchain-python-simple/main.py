from langchain.llms import Ollama

input = input("What is your question?")
llm = Ollama(model="llama3")
res = llm.predict(input)
print (res)
