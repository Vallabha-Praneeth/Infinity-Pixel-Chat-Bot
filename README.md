# Infinity Pixel Chat Bot

<div align="center">

**AI-Powered Customer Service Automation with Intelligent Ticket Management**

An advanced RAG (Retrieval-Augmented Generation) chatbot system that combines artificial intelligence with automated ticket management to deliver instant, intelligent customer support 24/7.

[![Production Ready](https://img.shields.io/badge/status-production%20ready-brightgreen)]()
[![Test Coverage](https://img.shields.io/badge/tests-100%25%20passing-success)]()
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![n8n](https://img.shields.io/badge/n8n-v1.118.2-orange)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[Features](#-features) •
[Quick Start](#-quick-start) •
[Documentation](#-documentation) •
[Contributing](#-contributing) •
[License](#-license)

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#️-architecture)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Documentation](#-documentation)
- [Testing](#-testing)
- [Project Structure](#️-project-structure)
- [Roadmap](#️-roadmap)
- [Contributing](#-contributing)
- [Changelog](#-changelog)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## 🌟 Features

### 🤖 Intelligent Conversation
- **AI-Powered Responses**: Uses OpenAI and LangChain for natural language understanding
- **Knowledge Base Integration**: Retrieves answers from your documentation via Pinecone vector store
- **Context-Aware**: Maintains conversation history for seamless interactions
- **Intent Detection**: Automatically determines when to create tickets vs. answer questions

### 🎫 Automated Ticket Management
- **Smart Ticket Creation**: Automatically captures all details without forms
- **Complete Lifecycle**: Create, update, check status, and close tickets through chat
- **Priority-Based SLA**: Automatic deadline calculation (High: 24h, Medium: 72h, Low: 5d)
- **Validation**: Prevents empty updates and modifications to closed tickets
- **Unique Ticket IDs**: Format `TCK-{timestamp}-{random}` for easy tracking

### 👥 Team Collaboration
- **Slack Integration**: Real-time notifications with direct Airtable links
- **Centralized Database**: All tickets stored in Airtable with complete history
- **Audit Trail**: Full conversation logs for compliance and quality review
- **SLA Tracking**: Visual indicators and deadline monitoring

### ⚡ 24/7 Availability
- **Always On**: Instant responses regardless of time zone or business hours
- **Unlimited Capacity**: Handle unlimited concurrent conversations
- **Consistent Quality**: Every customer receives accurate, up-to-date information
- **Scalable**: Grows with your business without proportional cost increases

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         USER                                │
│                      (Chat Interface)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │ Chat Message
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              RAG WORKFLOW (n8n)                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AI Agent (OpenAI + LangChain)                      │   │
│  │  ├─→ Pinecone Vector Store → Knowledge Base        │   │
│  │  └─→ Ticket Manager Tool → Sub-Workflow            │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│        TICKET MANAGER WORKFLOW (n8n)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Action Router (create/status/update/close)         │   │
│  │  ├─→ Airtable (Database)                            │   │
│  │  └─→ Slack (Notifications)                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Workflow Automation** | n8n Cloud | Orchestrates all workflows |
| **Database** | Airtable | Stores tickets and history |
| **AI/LLM** | OpenAI (LangChain) | Natural language processing |
| **Vector Store** | Pinecone | Knowledge base embeddings |
| **Document Source** | Google Drive | Knowledge base documents |
| **Notifications** | Slack | Team alerts |
| **Testing** | Bash (curl, jq) | Automated test suite |

---

## 🚀 Quick Start

### Prerequisites

- n8n Cloud account (v1.118.2+)
- Airtable account with API access
- OpenAI API key
- Pinecone account and API key
- Google Drive with knowledge base documents
- Slack workspace (optional, for notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Vallabha-Praneeth/Infinity-Pixel-Chat-Bot.git
   cd Infinity-Pixel-Chat-Bot
   ```

2. **Import workflows to n8n**
   - Import `workflows/RAG Workflow For( Customer service chat-bot).json`
   - Import `workflows/Ticket Manager (Airtable).json`
   - Import `workflows/Slack Actions.json` (optional)

3. **Configure credentials in n8n**
   - Add Airtable Personal Access Token
   - Add OpenAI API credentials
   - Add Pinecone API credentials
   - Add Google Drive OAuth2 credentials
   - Add Slack credentials (if using notifications)

4. **Set up Airtable**
   - Create a "Tickets" table using the schema in `airtable_tickets_template.csv`
   - Note your Base ID and Table ID
   - Update workflow with your IDs

5. **Configure environment variables**
   ```bash
   export N8N_WEBHOOK_BASE="https://your-n8n-instance.app.n8n.cloud"
   export N8N_TICKET_WEBHOOK_PATH="/webhook/tt"
   ```

6. **Activate workflows**
   - Activate "Ticket Manager (Airtable)" workflow
   - Activate "RAG Workflow" with chat trigger

7. **Run tests**
   ```bash
   cd tests
   chmod +x *.sh
   ./all_test.sh
   ```

   Expected output: ✅ All 6 tests passing

For detailed setup instructions, see [docs/QUICK_START.md](docs/QUICK_START.md)

---

## 💬 Usage

### For Customers

Simply chat naturally with the bot:

```
User: "How do I reset my password?"
Bot: [Provides step-by-step instructions from knowledge base]

User: "I'm getting a 403 error when accessing billing"
Bot: "I've created ticket TCK-1733148920123-456 for your issue..."

User: "What's the status of ticket TCK-1733148920123-456?"
Bot: "Ticket TCK-1733148920123-456 is currently open..."
```

### API Reference

**Webhook Endpoint**: `POST /webhook/tt`

<details>
<summary><b>Create Ticket</b></summary>

```json
{
  "action": "create",
  "name": "John Doe",
  "email": "john@example.com",
  "subject": "Cannot login",
  "description": "Getting 403 error when accessing dashboard",
  "priority": "high"
}
```

**Response:**
```json
{
  "action": "create",
  "ticketId": "TCK-1733148920123-456",
  "status": "open",
  "priority": "high",
  "messageForUser": "I've created ticket TCK-1733148920123-456..."
}
```
</details>

<details>
<summary><b>Check Status</b></summary>

```json
{
  "action": "status",
  "ticketId": "TCK-1733148920123-456"
}
```
</details>

<details>
<summary><b>Update Ticket</b></summary>

```json
{
  "action": "update",
  "ticketId": "TCK-1733148920123-456",
  "description": "Tried clearing cache, still not working"
}
```
</details>

<details>
<summary><b>Close Ticket</b></summary>

```json
{
  "action": "close",
  "ticketId": "TCK-1733148920123-456"
}
```
</details>

---

## 📚 Documentation

Comprehensive documentation is available in the `docs/` folder:

| Document | Description |
|----------|-------------|
| **[Quick Start Guide](docs/QUICK_START.md)** | 30-minute setup guide |
| **[Technical Documentation](RAG_Customer_Service_Chatbot_Technical_Documentation.docx)** | Complete technical reference |
| **[Business Overview](RAG_Customer_Service_Chatbot_Business_Overview.docx)** | Non-technical stakeholder doc |
| **[Fix Instructions](docs/FIX_INSTRUCTIONS.md)** | Troubleshooting guide |
| **[Testing Plan](docs/TESTING_PLAN.md)** | Testing strategy |
| **[Architecture Discussion](docs/architecture-webhook-vs-subworkflow-discussion.md)** | Design decisions |

---

## 🧪 Testing

The project includes comprehensive test coverage (100% - 6/6 tests passing):

```bash
# Run all tests
cd tests
./all_test.sh

# Individual test scripts
./test_create.sh                    # Test ticket creation
./test_status.sh <ticketId>         # Test status check
./test_close_bug_reproduction.sh    # Test close functionality
./test_all_actions_responses.sh     # Validate all actions
```

### Test Coverage

- ✅ Create ticket with all fields
- ✅ Status check existing ticket
- ✅ Update with valid text
- ✅ Update with empty text (validation)
- ✅ Close ticket
- ✅ Update closed ticket (validation)
- ✅ Ticket ID preservation
- ✅ Response format validation

---

## 🗂️ Project Structure

```
infinity-pixel-chatbot/
├── .github/                        # GitHub templates
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── config.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── workflows/                      # n8n workflow definitions
│   ├── RAG Workflow For( Customer service chat-bot).json
│   ├── Ticket Manager (Airtable).json
│   ├── Slack Actions.json
│   └── customer_notifications_workflow.json
├── docs/                           # Documentation
│   ├── QUICK_START.md
│   ├── FIX_INSTRUCTIONS.md
│   ├── TESTING_PLAN.md
│   ├── DIAGNOSIS_CLOSE_BUG.md
│   └── ...
├── tests/                          # Test suite
│   ├── all_test.sh
│   ├── test_create.sh
│   ├── test_status.sh
│   ├── test_close_bug_reproduction.sh
│   └── test_all_actions_responses.sh
├── scripts/                        # Utility scripts
│   ├── create_technical_doc.py
│   └── create_business_doc.py
├── airtable_tickets_template.csv   # Database schema
├── README.md                       # This file
├── CONTRIBUTING.md                 # Contribution guidelines
├── CHANGELOG.md                    # Version history
├── LICENSE                         # MIT License
└── .gitignore                      # Git ignore rules
```

---

## 🗺️ Roadmap

### ✅ Version 1.0 (Current)
- RAG-powered chatbot with AI intelligence
- Automated ticket management (CRUD)
- Integration with n8n, Airtable, Pinecone, Slack
- 100% test coverage
- Comprehensive documentation

### 🚧 Version 1.1 (Q1 2025)
- [ ] Enhanced Slack notifications with Airtable links
- [ ] SLA breach alerts and monitoring
- [ ] Stale ticket reminders
- [ ] Customer satisfaction surveys

### 📅 Version 1.2 (Q2 2025)
- [ ] Multi-agent assignment system
- [ ] Advanced analytics dashboard
- [ ] Custom fields for industry-specific data
- [ ] Multi-language support

### 🔮 Version 2.0 (Q3 2025)
- [ ] Multi-table database design
- [ ] Role-based access control
- [ ] CRM integration
- [ ] Predictive issue detection

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/Infinity-Pixel-Chat-Bot.git
cd Infinity-Pixel-Chat-Bot

# Set up environment
export N8N_WEBHOOK_BASE="https://your-n8n-instance.app.n8n.cloud"
export N8N_TICKET_WEBHOOK_PATH="/webhook/tt"

# Run tests
cd tests
./all_test.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📝 Changelog

All notable changes to this project are documented in [CHANGELOG.md](CHANGELOG.md).

**Latest Release: v1.0.0** - December 15, 2024
- Initial production release
- 100% test coverage
- Complete documentation suite
- Professional project structure

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Built with these amazing technologies:

- [n8n](https://n8n.io) - Workflow Automation Platform
- [OpenAI](https://openai.com) - AI/LLM Provider
- [LangChain](https://python.langchain.com) - AI Framework
- [Pinecone](https://www.pinecone.io) - Vector Database
- [Airtable](https://airtable.com) - Database Platform
- [Slack](https://slack.com) - Team Communication

---

## 📞 Support

- 📖 **Documentation**: Browse the [docs](docs/) folder
- 🐛 **Bug Reports**: [Open an issue](https://github.com/Vallabha-Praneeth/Infinity-Pixel-Chat-Bot/issues/new?template=bug_report.md)
- 💡 **Feature Requests**: [Request a feature](https://github.com/Vallabha-Praneeth/Infinity-Pixel-Chat-Bot/issues/new?template=feature_request.md)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/Vallabha-Praneeth/Infinity-Pixel-Chat-Bot/discussions)

---

<div align="center">

**Infinity Pixel Chat Bot** - Intelligent automation meeting real business needs.

Made with ❤️ by the Infinity Pixel team

[⬆ back to top](#infinity-pixel-chat-bot)

</div>
