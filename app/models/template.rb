class Template < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :prompt_template, presence: true
  
  # Default templates as constants
  DEFAULTS = {
    'standard' => {
      name: 'standard',
      prompt_template: <<~PROMPT.strip,
        Analyze the following content and provide:
        1. A concise title
        2. A clear summary (2-3 paragraphs)
        3. Key points (bullet list)
        4. Suggested tags
        
        Content: {{content}}
        Context: {{context}}
      PROMPT
      markdown_template: <<~MARKDOWN.strip
        ---
        created: {{created_at}}
        tags: {{tags}}
        type: {{content_type}}
        ---
        
        # {{title}}
        
        {{context_section}}
        
        ## Summary
        
        {{summary}}
        
        ## Key Points
        
        {{key_points}}
        
        {{related_notes_section}}
      MARKDOWN
    },
    'conversation' => {
      name: 'conversation',
      prompt_template: <<~PROMPT.strip,
        Summarize this conversation and extract the main takeaways.
        
        Conversation: {{content}}
      PROMPT
      markdown_template: <<~MARKDOWN.strip
        # Conversation: {{context}}
        
        {{summary}}
        
        ## Main Takeaways
        
        {{key_points}}
      MARKDOWN
    }
  }.freeze


    # Class method to access defaults
  def self.defaults
    DEFAULTS
  end
end