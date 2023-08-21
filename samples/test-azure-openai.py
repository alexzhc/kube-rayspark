#!/usr/bin/env python
import os
import openai

from langchain.llms import AzureOpenAI
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain, SimpleSequentialChain
from langchain.chat_models import ChatOpenAI, ChatAnthropic, AzureChatOpenAI
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler
from langchain.schema import HumanMessage, SystemMessage

# Azure AI info in envs
# os.environ["OPENAI_API_TYPE"] = "azure" 
# os.environ["OPENAI_API_VERSION"] = "2023-05-15"
# os.environ["OPENAI_API_BASE"] = "https://daocloud-01.openai.azure.com/"
# os.environ["OPENAI_API_KEY"] = ""
# DEPLOYMENT_NAME = "openai-01"

llm = AzureOpenAI(deployment_name=os.environ["AZURE_OPENAPI_DEPLOYMENT_NAME"], model_name="gpt-35-turbo-16k",
                  temperature=0) 

# llm("Tell me a joke")

# # here: Azure OpenAI information is set up bash envs
chat = AzureChatOpenAI(
    openai_api_base=os.environ["OPENAI_API_BASE"],
    openai_api_version=os.environ["OPENAI_API_VERSION"],
    deployment_name=os.environ["OPENAI_AZURE_DEPLOYMENT_NAME"],
    openai_api_key=os.environ["OPENAI_API_KEY"],
    openai_api_type=os.environ["OPENAI_API_TYPE"],
)

text = "Tell me a joke"

result = chat([HumanMessage(content=text)])

print(result)