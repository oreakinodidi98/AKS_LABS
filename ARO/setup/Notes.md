# ARO

## Set Up

[Guide](https://cloud.redhat.com/experts/quickstart-aro/)

- make sure to have [quota](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/newsupportrequest)
- Requires Vnet and 2x Subment one for master and worker node
- Also remeber to Disable network policies for Private Link Service on the control plane subnet. So AREs can work on cluster
- Create cluster -> takes 30-45 min

To delete can use:

```bash
az aro delete -y \
  --resource-group $AZR_RESOURCE_GROUP \
  --name $AZR_CLUSTER
```

```bash
az group delete -y \
  --name $AZR_RESOURCE_GROUP
```

## Red Hat Developer Lightspeed

[Documentation](https://www.redhat.com/en/products/developer-lightspeed)

- **What**: Set of AI tools helping software development teams boost their productivity on openshit. Extension in VS code
- **Who**: For Developers
- **How**: Users get specialized, domain-specific answers within Red Hat **Developer Hub** and Red Hat’s **migration toolkit for applications**
  - **Migration toolkit for applications**: Focus on helping users modernize their applications faster with the help of AI-generated code tailored to your custom applications
    - Assists with source code refactoring within your integrated development environment (IDE).
    - Provides explanations and recommended code changes, and apply fixes with the click of a button
    - [Document](https://developers.redhat.com/products/mta/developer-lightspeed?extIdCarryOver=true&intcmp=7013a0000038AoiAAE&sc_cid=7013a000003SxHRAA0)
    - [MTA Demo](https://www.youtube.com/watch?v=DBQTiKAoGiA&t=9s)
    - MTA = Migrration Toolkit for Applications
    - Helps organizations safely Migrate and Modernize their application portfolio to leverage Openshift
      - VS Code extension
      - **Configuration**: Uses Yaml to define Model in VS code -> From Openshift, AzureOpenAI, Amazon Bedrock, Deepseek, GoogleGenAI
      - **Profiles and targets**: Configures Modernization Profiles and targets. E.G what we want to modernize from , Java -> Quarkus
      - **Application Analysis**: Can Add custom rules -> Run Analysis with a specific target profile, find potential issues
      - **Modernize with GenAI**: Goes through Analysis and producess solutions from the analysis so does Migrations/Modernization changes if neccessary.
      - **Agentic AI**: AI agents will gfix things that affect what has been resolved by GenAI in previous step. So fix related issues to the first solution
      - **Solution Server**: MCP server in openshift enviroment. Persistent memory of all the resolutions that have been done, allowing you to enforce patterns and practices for future use
        - Leans from migration to enhance users experice. Has visibility to existing rules, solved incidents and manual overids. Migration metrics; Recordds how incidents are solved; Mine insights of solutions; contexts hinting for better generation
      - Can scale to 200x applications
  - **Developer Hub**: Use a chat interface within Red Hat Developer Hub for help with non-coding tasks, supported by information from Red Hat’s Developer Hub knowledge base.
  - Essentially GHCP chat mode
  - Use cases: generate first drafts of technical documentation, ask how to do a specific task, explore application design approaches, and more.
    - Can use to plan and create unit tests
    - Extension in VS code
    - Can be hosted in pod in openshift instead of Local
    - Connects to CI/CD
    - Can change models
    - [Demo](https://www.youtube.com/watch?v=HPPOW1nOexM&t=1s)
    - [Document](https://developers.redhat.com/products/rhdh/developer-lightspeed?extIdCarryOver=true&intcmp=7013a0000038AoiAAE&sc_cid=7013a000003SxHRAA0)
- **Benifits**:
  - **Workflow** integration: Reduce context-switching. Can access help without leaving your primary workspace.
  - **Context**: Uses Workspace context to answer questions
  - **Privacy**: Can bring your preferred large language model (LLM) and retain control over AI model performance, cost, and data privacy.
- **Why/USP**:
  - **MTA**: Unlike traditional coding assistants, Lightspeed for migration toolkit for applications is guided by MTA’s static code analysis and past migrations to suggest accurate code solutions from the start and also improve them over time. This helps developers refactor applications faster and predictably.
  - Optionally, you can also turn on “agent mode” to have built-in AI agents analyze your application to search and fix new issues that may arise after changing your code. This helps preserve functionality.
  - Can configure GenAI model used for this process. Can create Modernization targets
  - **Developer hub**: Boost productivity with an AI assistant that helps with daily non-coding tasks
  - AI virtual assistant for speeding up non-coding developer tasks. Through a chat-like interface, directly from the Developer Hub console, it helps with exploring software design approaches, drafting documentation and deployment artifacts, troubleshooting issues, and more.
  - Create planning for solutions
  - Need a subscribtion test