# Infinity Pixel Chat Bot

**AI-Powered Customer Service Automation with Intelligent Ticket Management**

An advanced RAG (Retrieval-Augmented Generation) chatbot system that combines artificial intelligence with automated ticket management to deliver instant, intelligent customer support 24/7.

[![Production Ready](https://img.shields.io/badge/status-production%20ready-brightgreen)]()
[![Test Coverage](https://img.shields.io/badge/tests-100%25%20passing-success)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

---

## 🌟 Features

### Intelligent Conversation
- **AI-Powered Responses**: Uses OpenAI and LangChain for natural language understanding
- **Knowledge Base Integration**: Retrieves answers from your documentation via Pinecone vector store
- **Context-Aware**: Maintains conversation history for seamless interactions

### Automated Ticket Management
- **Smart Ticket Creation**: Automatically captures all details without forms
- **Complete Lifecycle**: Create, update, check status, and close tickets through chat
- **Priority-Based SLA**: Automatic deadline calculation (High: 24h, Medium: 72h, Low: 5d)
- **Validation**: Prevents empty updates and modifications to closed tickets

### Team Collaboration
- **Slack Integration**: Real-time notifications with direct Airtable links
- **Centralized Database**: All tickets stored in Airtable with complete history
- **Audit Trail**: Full conversation logs for compliance and quality review

### 24/7 Availability
- **Always On**: Instant responses regardless of time zone or business hours
- **Unlimited Capacity**: Handle unlimited concurrent conversations
- **Consistent Quality**: Every customer receives accurate, up-to-date information

---

## 🏗️ Architecture

```
User → Chat Interface
         ↓
    RAG Workflow (n8n)
         ├─→ Pinecone Vector Store → Knowledge Base Answers
         └─→ Ticket Manager Sub-Workflow
                  ├─→ Airtable (Database)
                  └─→ Slack (Notifications)
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Workflow Automation | n8n Cloud |
| Database | Airtable |
| AI/LLM | OpenAI (LangChain) |
| Vector Store | Pinecone |
| Document Source | Google Drive |
| Notifications | Slack |
| Testing | Bash scripts (curl, jq) |

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
   - Test webhook endpoint

7. **Run tests**
   ```bash
   chmod +x *.sh
   ./all_test.sh
   ```

---

## 📚 Documentation

Comprehensive documentation is available in multiple formats:

- **[Technical Documentation](./RAG_Customer_Service_Chatbot_Technical_Documentation.docx)** - Complete technical reference for developers
- **[Business Overview](./RAG_Customer_Service_Chatbot_Business_Overview.docx)** - Non-technical overview for stakeholders
- **[Quick Start Guide](./QUICK_START.md)** - 30-minute setup guide
- **[Fix Instructions](./FIX_INSTRUCTIONS.md)** - Troubleshooting and bug fixes
- **[Testing Plan](./TESTING_PLAN.md)** - Comprehensive testing strategy

---

## 🎯 Usage

### For Customers

Simply chat naturally with the bot:

```
User: "How do I reset my password?"
Bot: [Provides step-by-step instructions from knowledge base]

User: "I'm getting a 403 error when accessing the billing dashboard"
Bot: "I've created ticket TCK-1733148920123-456 for your issue..."

User: "What's the status of ticket TCK-1733148920123-456?"
Bot: "Ticket TCK-1733148920123-456 is currently open..."
```

### API Reference

**Webhook Endpoint**: `POST /webhook/tt`

**Create Ticket**:
```json
{
  "action": "create",
  "name": "John Doe",
  "email": "john@example.com",
  "subject": "Cannot login",
  "description": "Getting 403 error",
  "priority": "high"
}
```

**Check Status**:
```json
{
  "action": "status",
  "ticketId": "TCK-1733148920123-456"
}
```

**Update Ticket**:
```json
{
  "action": "update",
  "ticketId": "TCK-1733148920123-456",
  "description": "Tried clearing cache, still not working"
}
```

**Close Ticket**:
```json
{
  "action": "close",
  "ticketId": "TCK-1733148920123-456"
}
```

---

## 🧪 Testing

The project includes comprehensive test coverage:

```bash
# Run all tests
./all_test.sh

# Individual test scripts
./test_create.sh                    # Test ticket creation
./test_status.sh <ticketId>         # Test status check
./test_close_bug_reproduction.sh    # Test close functionality
```

**Test Coverage**: 6/6 core tests passing (100%)

---

## 📊 Key Metrics

Track these KPIs to measure system effectiveness:

- **Response Time**: < 60 seconds for chatbot responses
- **Availability**: 24/7 uptime
- **Automation Rate**: % of inquiries handled without human intervention
- **SLA Compliance**: % of tickets resolved within deadline
- **Customer Satisfaction**: Post-interaction survey scores

---

## 🛠️ Project Structure

```
infinity-pixel-chatbot/
├── workflows/                                          # n8n workflow definitions
│   ├── RAG Workflow For( Customer service chat-bot).json
│   ├── Ticket Manager (Airtable).json
│   ├── Slack Actions.json
│   └── customer_notifications_workflow.json
├── airtable_tickets_template.csv                      # Database schema
├── test_*.sh                                          # Test scripts
├── all_test.sh                                        # Complete test suite
├── CLAUDE.md                                          # Project knowledge base
├── QUICK_START.md                                     # Quick setup guide
├── FIX_INSTRUCTIONS.md                                # Troubleshooting
├── TESTING_PLAN.md                                    # Testing strategy
├── *.docx                                             # Comprehensive docs
└── README.md                                          # This file
```

---

## 🐛 Troubleshooting

### Common Issues

**Q: Close action returns wrong ticket ID**
- **Cause**: Build Response nodes connected to Slack instead of being end nodes
- **Solution**: See [FIX_INSTRUCTIONS.md](./FIX_INSTRUCTIONS.md)

**Q: Empty responses from update/status**
- **Cause**: Response nodes not terminal
- **Solution**: Ensure all Build Response nodes have no outgoing connections

**Q: AI agent not calling ticket tool**
- **Cause**: Unclear intent or missing keywords
- **Solution**: Improve AI agent prompt, add explicit tool instructions

For more troubleshooting, see the [Technical Documentation](./RAG_Customer_Service_Chatbot_Technical_Documentation.docx).

---

## 🗺️ Roadmap

### Phase 1: Enhanced Notifications ✅
- Real-time Slack notifications with ticket details
- Direct Airtable links for one-click access
- Priority-based routing

### Phase 2: Proactive Monitoring (Q1 2025)
- SLA breach alerts
- Stale ticket reminders
- Daily/weekly summary reports
- Customer satisfaction surveys

### Phase 3: Advanced Features (Q2 2025)
- Multi-agent assignment
- Advanced analytics dashboard
- Custom fields for industry-specific data
- Multi-language support

### Phase 4: Enterprise Features (Q3 2025)
- Multi-table database design
- Role-based access control
- Advanced reporting and BI
- CRM integration

---

## 💡 Business Value

### Quantifiable Benefits

- **Response Time**: Instant (seconds) vs. traditional hours/days
- **Availability**: 24/7 vs. business hours only
- **Capacity**: Unlimited concurrent conversations
- **Consistency**: 100% consistent, accurate information
- **Scalability**: No additional cost as volume increases

### Cost Reduction

- Reduced time on repetitive questions
- Lower overhead for ticket management
- Fewer escalations due to complete information
- Reduced training time for new support staff

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Built with:
- [n8n](https://n8n.io) - Workflow Automation
- [OpenAI](https://openai.com) - AI/LLM
- [LangChain](https://python.langchain.com) - AI Framework
- [Pinecone](https://www.pinecone.io) - Vector Database
- [Airtable](https://airtable.com) - Database
- [Slack](https://slack.com) - Team Communication

---

## 📞 Support

For technical support or questions:
- Open an issue in this repository
- Refer to the comprehensive documentation
- Check the troubleshooting guides

---

**Infinity Pixel Chat Bot** - Intelligent automation meeting real business needs.

*Last Updated: December 2024*
