import logging
import os
import streamlit
from dotenv import load_dotenv

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import AssistantMessage, SystemMessage, UserMessage
from azure.identity import DefaultAzureCredential

# Load environment variables from .env file
load_dotenv()

# Read environment variables
TITLE = os.getenv("TITLE", "Demo chatbot running on AKS Automatic, powered by Microsoft Foundry")
AGENT_INSTRUCTIONS = os.getenv("SYSTEM_PROMPT", "You are a helpful assistant reachable through the Model Context Protocol.")
TEMPERATURE = float(os.getenv("TEMPERATURE", "0.5"))
MODEL_ENDPOINT = os.getenv("MODEL_ENDPOINT", "https://ore-mcp-foundry.services.ai.azure.com/models")
MODEL_DEPLOYMENT = os.getenv("MODEL_DEPLOYMENT", "gpt-5.4-mini")
PORT = int(os.environ.get("PORT", 8080))
IMAGE_NAME = os.getenv("IMAGE_NAME", "chatbot.png")
credential = DefaultAzureCredential()
model_client = None

# open file
try:
  with open("/etc/hostname", "r") as file:
    HOSTNAME = file.read().strip()
except OSError:
  HOSTNAME = os.getenv("HOSTNAME", "unknown")
  
def main():
  # call the function to configure the model client
  configure_model_client()
  
  # call the function to customize streamlit ui
  customize_streamlit_ui()
  
  col1, col2 = streamlit.columns([1, 6])

  # Display the robot image
  with col1:
    streamlit.image(image = os.path.join("image", IMAGE_NAME), width = 100)

  # Display the header
  with col2:
    streamlit.header(TITLE)

  col3, col4, col5 = streamlit.columns([6, 1, 1])

  # Create text input in column 1
  with col3:
    user_input = streamlit.text_input(" ", key = "user", on_change = user_change)

  # Create send button in column 2
  with col4:
    streamlit.button(label = "Post")

  # Create clean button in column 3
  with col5:
    streamlit.button(label = "Clean", on_click = clean_click)

  if streamlit.session_state['generated']:
    for i in range(len(streamlit.session_state['generated']) - 1, -1, -1):
       streamlit.markdown("**:blue[{}]**".format(streamlit.session_state['past'][i]))
       streamlit.markdown(streamlit.session_state['generated'][i])
       streamlit.markdown("---answered by " + str(HOSTNAME))
       streamlit.markdown("""---""")

# function to configure the model client
def configure_model_client():
# use global keyword to specify that we are referring to the global variable model_client
  global model_client

  model_client = ChatCompletionsClient(
    endpoint=MODEL_ENDPOINT,
    credential=credential,
    credential_scopes=["https://ai.azure.com/.default"],
  )

# function to customize the streamlit ui
def customize_streamlit_ui():
  # Customize Streamlit UI using CSS
  streamlit.set_page_config(page_title='Chatbot on AKS automatic powered by Microsoft Foundry')
  streamlit.markdown("""
  <style>

  div.stButton > button:first-child {
    background-color: #eb5424;
    color: white;
    font-size: 20px;
    font-weight: bold;
    border-radius: 0.5rem;
    padding: 0.5rem 1rem;
    border: none;
    box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
    width: 500 px;
    height: 42px;
    transition: all 0.2s ease-in-out;
  } 

  div.stButton > button:first-child:hover {
    transform: translateY(-3px);
    box-shadow: 0 1rem 2rem rgba(0,0,0,0.15);
  }

  div.stButton > button:first-child:active {
    transform: translateY(-1px);
    box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
  }

  div.stButton > button:focus:not(:focus-visible) {
    color: #FFFFFF;
  }

  @media only screen and (min-width: 1000px) {
    /* For desktop: */
    div {
      font-family: 'Roboto', sans-serif;
    }

    div.stButton > button:first-child {
      background-color: #0066cc;
      color: white;
      font-size: 20px;
      font-weight: bold;
      border-radius: 0.5rem;
      padding: 0.5rem 1rem;
      border: none;
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
      width: 500 px;
      height: 42px;
      transition: all 0.2s ease-in-out;
      position: relative;
      bottom: -32px;
      right: 0px;
    } 

    div.stButton > button:first-child:hover {
      transform: translateY(-3px);
      box-shadow: 0 1rem 2rem rgba(0,0,0,0.15);
    }

    div.stButton > button:first-child:active {
      transform: translateY(-1px);
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
    }

    div.stButton > button:focus:not(:focus-visible) {
      color: #FFFFFF;
    }

    input {
      border-radius: 0.5rem;
      padding: 0.5rem 1rem;
      border: none;
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
      transition: all 0.2s ease-in-out;
      height: 40px;
    }
  }

  footer {visibility: hidden;}
  </style>
  """, unsafe_allow_html=True)

  # Initialize Streamlit session state
  if 'prompts' not in streamlit.session_state:
    streamlit.session_state['prompts'] = [{"role": "system", "content": os.system}]

  if 'generated' not in streamlit.session_state:
    streamlit.session_state['generated'] = []

  if 'past' not in streamlit.session_state:
    streamlit.session_state['past'] = []

  if 'user' not in streamlit.session_state:
    streamlit.session_state['user'] = ""

# Send the user prompt to the configured model backend.
def generate_response(prompt):
  try:
    streamlit.session_state['prompts'].append({"role": "user", "content": prompt})

    message_types = {
      "system": SystemMessage,
      "user": UserMessage,
      "assistant": AssistantMessage,
    }
    messages = [
      message_types[item["role"]](content=item["content"])
      for item in streamlit.session_state['prompts']
    ]
    completion = model_client.complete(
      model=MODEL_DEPLOYMENT,
      messages=messages,
      temperature=TEMPERATURE,
    )
    
    message = completion.choices[0].message.content
    return message
  except Exception as e:
    logging.exception(f"Exception in generate_response: {e}")

# function to reset Streamlit session state to start a new chat from scratch
def clean_click():
  streamlit.session_state['prompts'] = [{"role": "system", "content": os.system}]
  streamlit.session_state['past'] = []
  streamlit.session_state['generated'] = []
  streamlit.session_state['user'] = ""

# function to Handle on_change event for user input
def user_change():
  # Avoid handling the event twice when clicking the Send button
  chat_input = streamlit.session_state['user']
  streamlit.session_state['user'] = ""
  if (chat_input == '' or
      (len(streamlit.session_state['past']) > 0 and chat_input == streamlit.session_state['past'][-1])):
    return
  
  # Generate response using the Foundry model deployment.
  if chat_input !=  '':
    output = generate_response(chat_input)
    
    # store the output
    streamlit.session_state['past'].append(chat_input)
    streamlit.session_state['generated'].append(output)
    streamlit.session_state['prompts'].append({"role": "assistant", "content": output})

if __name__ == '__main__':
  main()