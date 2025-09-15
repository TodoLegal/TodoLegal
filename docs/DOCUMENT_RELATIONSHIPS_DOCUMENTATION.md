# Document Relationships Implementation Documentation

## Overview

The Document Relationships feature enables the TodoLegal application to track and manage legal document interdependencies, allowing users to establish connections between documents that amend, repeal, or otherwise modify each other. This is crucial for legal document management where understanding the relationships between laws, regulations, and other legal instruments is essential.

## Architecture & Design Patterns

### 1. Model-View-Controller (MVC) Pattern
The implementation follows Rails' MVC architecture:
- **Model**: `DocumentRelationship` - handles data logic and validations
- **View**: Partial templates for rendering the relationships interface
- **Controller**: `DocumentRelationshipsController` - manages HTTP requests and business logic

### 2. Service Object Pattern
While not explicitly implemented as separate service objects, the controller encapsulates complex business logic for URL parsing and relationship creation, following service object principles.

### 3. Concern Pattern
The `Document` model includes relationship-specific methods and associations, effectively acting as a concern for relationship management.

## Core Components

### 1. DocumentRelationship Model

**Purpose**: Represents the many-to-many relationship between documents with specific modification types.

**Key Features**:
```ruby
class DocumentRelationship < ApplicationRecord
  belongs_to :source_document, class_name: 'Document'
  belongs_to :target_document, class_name: 'Document'
  
  enum modification_type: {
    amend: 'amend',      # Amendment/Reform
    repeal: 'repeal'     # Repeal/Derogation
  }
end
```

**Validations**:
- Prevents duplicate relationships (same source, target, and modification type)
- Prevents self-relationships (document cannot modify itself)
- Ensures required fields are present

**Why this design**:
- **Flexible**: Can easily add new modification types
- **Normalized**: Avoids data duplication
- **Trackable**: Maintains relationship history
- **Queryable**: Easy to find related documents

### 2. Document Model Extensions

**Associations Added**:
```ruby
class Document < ApplicationRecord
  # Document-document relationships
  has_many :source_relationships, class_name: 'DocumentRelationship', 
           foreign_key: 'source_document_id', dependent: :destroy
  has_many :target_relationships, class_name: 'DocumentRelationship', 
           foreign_key: 'target_document_id', dependent: :destroy
           
  # Convenience methods for specific relationship types
  has_many :amended_documents, -> { where(document_relationships: { modification_type: 'amend' }) },
           through: :source_relationships, source: :target_document
  has_many :repealed_documents, -> { where(document_relationships: { modification_type: 'repeal' }) },
           through: :source_relationships, source: :target_document
end
```

**Why this approach**:
- **Clear semantics**: Easy to understand what each association represents
- **Performance**: Enables efficient querying with joins
- **Maintainability**: Changes to relationship logic are centralized

### 3. DocumentRelationshipsController

**Purpose**: Handles CRUD operations for document relationships with URL-based document linking.

**Key Methods**:

#### `create` Action
- Extracts document ID from provided URLs
- Validates document existence
- Creates appropriate relationship based on modification type
- Uses Turbo for seamless UI updates

#### `destroy` Action
- Safely removes relationships
- Updates UI via Turbo streams
- Maintains referential integrity

**URL Parsing Logic**:
```ruby
def extract_document_id_from_url(url)
  # Handles various URL formats:
  # - /documents/123
  # - /documents/123/edit
  # - https://domain.com/documents/123
  match = url.match(/\/documents\/(\d+)/)
  match ? match[1].to_i : nil
end
```

**Why URL-based linking**:
- **User-friendly**: Users can copy-paste document URLs
- **Flexible**: Works with various URL formats
- **Validation**: Ensures referenced documents exist
- **Error handling**: Graceful failure for invalid URLs


## User Interface Implementation

### 1. Turbo Framework Integration

**Why Turbo**: 
- **Seamless updates**: No page reloads needed
- **Performance**: Only updates necessary DOM elements
- **Modern UX**: Feels like a single-page application
- **Rails integration**: Works naturally with Rails conventions

**Implementation Pattern:**

The relationships UI is structured for clarity and Turbo efficiency:

- `documents/_document_relationships.html.erb`: Contains the section container, the static title `<h4>Relaciones del Documento</h4>`, the flash area, and renders the turbo frame partial.
- `documents/relationships/_document_relationships_section.html.erb`: Contains only the content inside the turbo frame (`document_relationships_section`).

```erb
<section class="document-relationships-container">
  <h4>Relaciones del Documento</h4>
  <div class="row">
    <div class="col-md-12">
      <%= turbo_frame_tag "autosave_flash_relationships" %>
    </div>
  </div>
  <%= render partial: "documents/relationships/document_relationships_section", locals: { document: document } %>
</section>
```

```erb
<%= turbo_frame_tag "document_relationships_section" do %>
  <!-- Relationship content (card, forms, etc.) -->
<% end %>
```

This pattern ensures:
- The title and section container are rendered only once and remain static.
- Only the content inside the turbo frame is replaced when relationships are added or removed.
- Turbo Stream responses update only the relevant frame, never duplicating the title or container.

**Turbo Stream Response Example:**
When a relationship is created or deleted, the controller responds with:
```ruby
turbo_stream.replace(
  "document_relationships_section",
  partial: "documents/relationships/document_relationships_section",
  locals: { document: current_document }
)
```
This ensures only the turbo frame content is updated, not the title or section container.

### 2. Common Mistakes and Solutions

#### Mistake: Duplicated Titles or Section Containers
**Problem:** If the title `<h4>` or section container is placed inside the turbo frame partial, every Turbo update will duplicate these elements in the DOM.

**Solution:** Always keep static elements (like section titles or containers) outside the turbo frame. Only dynamic, updatable content should be inside the turbo frame partial.

#### Mistake: Turbo Frame Not Updating as Expected
**Problem:** If the turbo frame tag's ID in the view does not match the ID used in the Turbo Stream response, the frame will not update.

**Solution:** Ensure the turbo frame tag and the Turbo Stream response use the exact same ID string.

#### Mistake: Rendering the Full Partial in Both the Main View and Turbo Frame
**Problem:** Rendering the same partial both outside and inside the turbo frame can lead to duplicated content.

**Solution:** Use a wrapper partial for static content and a separate partial for the turbo frame content. Render the turbo frame partial only where dynamic updates are needed.

### 2. Stimulus Controllers (Ready for Implementation)

**Planned Features**:
- Auto-completion for document URLs
- Real-time validation feedback
- Dynamic form updates based on relationship type

### 3. Form Design

**Modification Type Selection**:
1. **Amended by** - Current document is target (being amended)
2. **Repealed by** - Current document is target (being repealed)
3. **Reformed to** - Current document is source (amending another)
4. **Repeals to** - Current document is source (repealing another)

**Why this terminology**:
- **Clear direction**: Users understand the relationship direction
- **Legal accuracy**: Matches legal terminology
- **Intuitive**: Natural language that legal professionals understand

## Data Flow & Business Logic

### 1. Relationship Creation Flow

```
User Input (URL + Type) → Controller → URL Validation → Document Lookup → 
Relationship Creation → Database Save → Turbo Update → UI Refresh
```

### 2. Relationship Types and Direction

| User Selection | Source Document | Target Document | Modification Type |
|----------------|-----------------|-----------------|-------------------|
| "Amended by"   | URL Document    | Current Doc     | amend             |
| "Repealed by"  | URL Document    | Current Doc     | repeal            |
| "Reformed to"  | Current Doc     | URL Document    | amend             |
| "Repeals to"   | Current Doc     | URL Document    | repeal            |

**Why this mapping**:
- **Consistent data model**: Always stores who modifies whom
- **Flexible queries**: Can find both "what this modifies" and "what modifies this"
- **Audit trail**: Clear record of modification history

## Error Handling & Validation

### 1. Application-Level Validations

```ruby
validates :source_document_id, uniqueness: { 
  scope: [:target_document_id, :modification_type],
  message: "ya tiene esta modificación con el documento destino" 
}

validate :no_self_relationship
```

### 2. Controller-Level Error Handling

- **URL parsing failures**: Clear error messages for invalid URLs
- **Document not found**: Informative feedback when referenced documents don't exist
- **Duplicate relationships**: Prevention of redundant connections
- **Self-relationships**: Blocks documents from referencing themselves

### 3. User Feedback Mechanisms

```ruby
def handle_error(error_msg, redirect_url, current_document_id)
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "autosave_flash_relationships",
        partial: "layouts/flash",
        locals: { 
          alert_origin: "relationships",
          alert_type: "danger",
          message: error_msg,
          fade_timeout: "5000"
        }
      )
    end
  end
end
```

## Database Design Considerations

### 1. Schema Structure

```sql
CREATE TABLE document_relationships (
  id BIGINT PRIMARY KEY,
  source_document_id BIGINT NOT NULL,
  target_document_id BIGINT NOT NULL,
  modification_type VARCHAR NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  FOREIGN KEY (source_document_id) REFERENCES documents(id),
  FOREIGN KEY (target_document_id) REFERENCES documents(id),
  
  UNIQUE(source_document_id, target_document_id, modification_type)
);
```

### 2. Indexing Strategy

- **Primary key**: Automatic index on `id`
- **Foreign keys**: Indexes on both `source_document_id` and `target_document_id`
- **Unique constraint**: Prevents duplicate relationships
- **Composite index**: On `(source_document_id, modification_type)` for performance

**Performance Benefits**:
- Fast lookups for document relationships
- Efficient joins between documents and relationships
- Quick validation of duplicate relationships

## Integration with Existing Codebase

### 1. Document Edit View Integration

**Location**: `app/views/documents/edit.html.erb`
```erb
<%= render partial: 'document_relationships', locals: { document: @document } %>
```

**Why this placement**:
- **Contextual**: Relationships are part of document editing workflow
- **Consistent**: Follows same pattern as document tags
- **Accessible**: Easy to find and modify relationships

### 2. Styling and UI Consistency

**CSS Classes Used**:
- Bootstrap 5 components for consistent styling
- Custom classes following existing patterns
- Responsive design matching the rest of the application

**Color-Coded Relationship Types**:
The implementation includes visual distinction for different relationship types using colored left borders:

```css
.relationship-group-amended-by {
  border-left-color: #4a90e2; /* Blue - reformado por */
}

.relationship-group-repealed-by {
  border-left-color: #d63031; /* Red - derogado por */
}

.relationship-group-amends {
  border-left-color: #00b894; /* Green - reforma a */
}

.relationship-group-repeals {
  border-left-color: #e17055; /* Orange - deroga a */
}
```

**Color Meaning**:
- **Blue (#4a90e2)**: "Reformado por" - Document is amended by others
- **Red (#d63031)**: "Derogado por" - Document is repealed by others  
- **Green (#00b894)**: "Reforma a" - Document amends others
- **Orange (#e17055)**: "Deroga a" - Document repeals others

**Enhanced Link Display**:
All relationship links now use the `document_display_text` helper to show:
- Document type (Decreto, Resolución, etc.)
- Primary identifier (name, issue_id, or ID)
- Consistent formatting across all relationship types

Example displays:
- "Decreto: Ley de Transparencia y Acceso a la Información"
- "Resolución: 15-2020"
- "Oficio: #1234"

### 3. Route Configuration

```ruby
resources :document_relationships
```

**RESTful routes provide**:
- Standard CRUD operations
- Predictable URL patterns
- Easy testing and maintenance

## Testing Considerations

### 1. Model Tests
- Validation testing (uniqueness, presence, self-relationship prevention)
- Association testing (belongs_to relationships work correctly)
- Enum testing (modification types work as expected)

### 2. Controller Tests
- URL parsing accuracy
- Error handling for invalid URLs
- Turbo stream responses
- Authentication and authorization

### 3. Integration Tests
- Complete user workflow (create, view, delete relationships)
- JavaScript functionality with Turbo
- Error scenarios and user feedback

### 4. Helper Tests
- `document_display_text` method accuracy
- Edge cases (missing document type, nil values)
- Formatting consistency across different document types

### 5. UI/Visual Tests
- Color coding displays correctly for each relationship type
- Link text formats properly with document type and identifier
- Responsive design across different screen sizes

## Security Considerations

### 1. Authorization
- Uses existing `authenticate_editor!` before_action
- Ensures only authorized users can modify relationships
- Consistent with application security model

### 2. Parameter Validation
- Strong parameters to prevent mass assignment
- URL validation to prevent injection attacks
- Document existence verification

### 3. Data Integrity
- Foreign key constraints prevent orphaned relationships
- Database-level unique constraints prevent duplicates
- Transaction-based operations for consistency

## Performance Optimization

### 1. Query Optimization
- Eager loading for relationship displays: `includes(:source_relationships, :target_relationships)`
- Scoped queries for specific relationship types
- Indexed foreign keys for fast lookups

### 2. Caching Strategy
- Page-level caching for relationship displays
- Fragment caching for relationship lists
- Cache invalidation on relationship changes

### 3. Frontend Performance
- Turbo frames limit DOM updates to necessary sections
- Minimal JavaScript for better performance
- Progressive enhancement approach

## Maintenance and Extensibility

### 1. Adding New Relationship Types

**Process**:
1. Add to enum in `DocumentRelationship` model
2. Update form options in view
3. Add handling in controller `create` method
4. Update documentation and tests

**Example**:
```ruby
enum modification_type: {
  amend: 'amend',
  repeal: 'repeal',
}
```

### 2. Extended Metadata

**Future enhancements**:
- Relationship effective dates
- Relationship descriptions/notes
- Version tracking for relationships
- Bulk relationship operations

### 3. API Extension

**Planned features**:
- REST API endpoints for relationships
- JSON serialization for external integrations
- Webhook notifications for relationship changes

## Monitoring and Analytics

### 1. Usage Metrics
- Track relationship creation frequency
- Monitor most-connected documents
- Analyze relationship type distribution

### 2. Error Monitoring
- Log URL parsing failures
- Track relationship creation errors
- Monitor performance bottlenecks

### 3. Data Quality
- Orphaned relationship detection
- Relationship consistency checks
- Automated cleanup procedures

## Best Practices Followed

### 1. Rails Conventions
- RESTful routing and controller actions
- Rails naming conventions for models and methods
- Standard Rails directory structure

### 2. Code Organization
- Single Responsibility Principle in controller methods
- DRY principle with partial templates
- Consistent error handling patterns

### 3. User Experience
- Progressive enhancement
- Graceful degradation for JavaScript failures
- Clear, actionable error messages
- Consistent visual feedback

## Future Enhancements

### 1. Advanced Features
- Bulk relationship import/export
- Relationship visualization graphs
- Historical relationship tracking
- Automated relationship suggestions

### 2. Performance Improvements
- Background job processing for large operations
- Real-time collaboration features
- Advanced caching strategies
- Database optimization

### 3. Integration Opportunities
- External legal database connections
- AI-powered relationship detection
- Document version control integration
- Legal citation parsing

## Conclusion

The Document Relationships implementation provides a robust, scalable solution for managing legal document interdependencies. It follows Rails best practices, integrates seamlessly with existing code, and provides a foundation for future enhancements. The modular design allows for easy maintenance and extension while ensuring data integrity and user experience quality.

The implementation successfully addresses the core requirements:
- ✅ Display existing relationships in document edit view
- ✅ Create new relationships via URL input
- ✅ Delete existing relationships
- ✅ Support for all four relationship types
- ✅ Proper direction handling (source vs target)
- ✅ URL validation and document existence checking
- ✅ Turbo integration for seamless UI updates
- ✅ Error handling with user feedback

This documentation serves as both a technical reference and a guide for future development work on the relationships feature.
