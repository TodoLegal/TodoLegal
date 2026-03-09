# TodoLegal System Architecture
## Current Service Layer & Database Design

**Last Updated:** February 2026  
**Status:** Production Architecture Documentation  
**Purpose:** Visual reference for system architecture and data flow  
**See also:** [LAW_DISPLAY_OPTIMIZATION.md](LAW_DISPLAY_OPTIMIZATION.md) for implementation narrative

---

## 📐 System Overview

### High-Level Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[Web Browser]
        Mobile[Mobile Browser]
        Stimulus[Stimulus Controllers<br/>law_infinite_scroll<br/>manifest_loader]
    end
    
    subgraph "Application Layer"
        Router[Rails Router<br/>routes.rb]
        LawsCtrl[LawsController<br/>show / load_chunk / manifest]
        AppCtrl[ApplicationController<br/>get_raw_law]
        Turbo[Turbo Streams<br/>Progressive chunk delivery]
        
        Router --> LawsCtrl
        LawsCtrl --> AppCtrl
        LawsCtrl --> Turbo
    end
    
    subgraph "Service Layer"
        LDS[LawDisplayService<br/>Main orchestrator<br/>546 lines]
        LSB[LawStreamBuilder<br/>Stream assembly<br/>258 lines]
        SR[ServiceResult<br/>Success/Failure pattern]
        Config[LawDisplayConfig<br/>Constants & settings]
        MB[Laws::ManifestBuilder<br/>Hierarchy builder<br/>230 lines]
        MC[Laws::ManifestCache<br/>Cache layer]
        WarmJob[WarmLawManifestJob<br/>Background cache warming]
        
        AppCtrl --> LDS
        LDS --> LSB
        LDS --> SR
        LDS -.uses.-> Config
        LDS --> MC
        MC --> MB
        WarmJob --> MC
    end
    
    subgraph "Model Layer"
        Law[Law Model<br/>after_commit: warm cache]
        Article[Article Model<br/>+ pg_search scopes]
        Structure[Structure Models<br/>Book, Title, Chapter, etc.]
        
        LDS --> Law
        LDS --> Article
        LDS --> Structure
        Law -.triggers.-> WarmJob
    end
    
    subgraph "Database Layer"
        PG[(PostgreSQL)]
        Articles[articles table<br/>+ body_tsv tsvector]
        GIN[GIN Index<br/>index_articles_on_body_tsv_gin]
        Trigger[Database Trigger<br/>articles_body_tsv_update]
        
        Article --> Articles
        Articles --> GIN
        Articles --> Trigger
        Trigger -.maintains.-> Articles
    end
    
    subgraph "Cache Layer"
        RailsCache[Rails.cache<br/>ManifestCache keys]
        MC --> RailsCache
    end
    
    Browser --> Router
    Mobile --> Router
    Stimulus -.AJAX.-> LawsCtrl
    
    style LDS fill:#d4edda,stroke:#28a745,color:#000000
    style LSB fill:#d4edda,stroke:#28a745,color:#000000
    style SR fill:#d4edda,stroke:#28a745,color:#000000
    style GIN fill:#d4edda,stroke:#28a745,color:#000000
    style MC fill:#d4edda,stroke:#28a745,color:#000000
    style Turbo fill:#d4edda,stroke:#28a745,color:#000000
```

---

## 🔄 Request Flow Diagrams

### 1. Normal Law Display (Chunked)

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant C as Controller
    participant LDS as LawDisplayService
    participant LSB as LawStreamBuilder
    participant DB as Database
    participant Cache as Cache Layer
    
    Note over U,Cache: Full Law Display with Chunked Loading
    
    U->>C: GET /laws/81?page=1
    activate C
    
    C->>LDS: call(law, user, params)
    activate LDS
    
    LDS->>LDS: determine_chunk_size()<br/>Returns: 100 articles
    
    LDS->>Cache: Check manifest cache
    Cache-->>LDS: Law metadata
    
    LDS->>DB: Load structure components<br/>(books, titles, chapters, etc.)
    DB-->>LDS: All structure (fast query)
    
    LDS->>DB: Load chunked articles<br/>LIMIT 100 OFFSET 0
    DB-->>LDS: First 100 articles
    
    LDS->>LDS: filter_structure_for_display()<br/>Match structure to articles
    
    LDS->>LSB: build(components, go_to_position)
    activate LSB
    
    LSB->>LSB: Organize by position<br/>Books → Titles → Chapters → Articles
    
    LSB-->>LDS: Interleaved stream + index items
    deactivate LSB
    
    LDS->>LDS: calculate_chunk_metadata()<br/>Page 1 of 24, has_more: true
    
    LDS-->>C: ServiceResult.success(display_data)
    deactivate LDS
    
    C->>C: Extract data from result
    C->>C: Apply law-specific access control
    
    C-->>U: Render view with stream
    deactivate C
    
    Note over U: User scrolls to bottom...
    
    U->>C: GET /laws/81?page=2 (AJAX)
    activate C
    C->>LDS: call(law, user, {page: 2})
    activate LDS
    
    LDS->>DB: Load articles<br/>LIMIT 100 OFFSET 100
    DB-->>LDS: Next 100 articles
    
    LDS->>LDS: filter_structure_for_display()<br/>Only NEW structure in range
    
    LDS->>LSB: build(components)
    activate LSB
    LSB-->>LDS: Next chunk stream
    deactivate LSB
    
    LDS-->>C: ServiceResult with chunk 2
    deactivate LDS
    
    C-->>U: Turbo Frame append
    deactivate C
    
    Note over U: Seamless content addition
```

---

### 2. Search Request Flow

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant C as Controller
    participant LDS as LawDisplayService
    participant Article as Article Model
    participant PG as PostgreSQL<br/>GIN Index
    participant SR as ServiceResult
    
    Note over U,SR: Full-Text Search with GIN Index
    
    U->>C: GET /laws/81?query=justicia
    activate C
    
    C->>LDS: call(law, user, {query: "justicia"})
    activate LDS
    
    LDS->>LDS: search_request?()<br/>Returns: true
    
    LDS->>Article: search_by_body_highlighted("justicia")
    activate Article
    
    Note over Article: Uses pg_search with<br/>tsvector_column: 'body_tsv'
    
    Article->>PG: SELECT * FROM articles<br/>WHERE body_tsv @@ plainto_tsquery('justicia')
    activate PG
    
    Note over PG: GIN Index Lookup
    
    PG->>PG: 1. Tokenize: 'justicia'
    PG->>PG: 2. Lookup in GIN index<br/>Token 'justicia' → [15, 23, 45, ...]
    PG->>PG: 3. Bitmap Index Scan<br/>Time: ~5-10ms
    PG->>PG: 4. Bitmap Heap Scan<br/>Fetch matching articles
    
    PG-->>Article: 89 matching articles<br/>Time: 11ms total ⚡
    deactivate PG
    
    Article->>Article: with_pg_search_highlight<br/>Apply highlighting
    
    Article-->>LDS: Highlighted results
    deactivate Article
    
    LDS->>LDS: Sort by position<br/>Apply result limit (1000)
    
    LDS->>SR: ServiceResult.success(data)
    activate SR
    SR-->>LDS: Success result
    deactivate SR
    
    LDS-->>C: Result with highlighted stream
    deactivate LDS
    
    C->>C: Extract display data
    C->>C: Track search analytics
    
    C-->>U: Render search results<br/>Total time: 837ms ⚡
    deactivate C
    
    Note over U: User sees highlighted results<br/>in 2-3 seconds
```

---

### 3. Focus Mode (Single Article Request)

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant C as Controller
    participant LDS as LawDisplayService
    participant Cache as ManifestCache
    participant DB as Database
    participant LSB as LawStreamBuilder
    
    Note over U,LSB: Jump to Specific Article with Context Window
    
    U->>C: GET /laws/81?articles=1545
    activate C
    
    C->>LDS: call(law, user, {articles: "1545"})
    activate LDS
    
    LDS->>LDS: article_filter_request?()<br/>Returns: true (single article)
    
    LDS->>DB: Find article by number<br/>WHERE number LIKE '%1545%'
    DB-->>LDS: Article at position 1545
    
    LDS->>Cache: article_by_position(law, 1545)
    activate Cache
    Cache-->>LDS: Article with global_index
    deactivate Cache
    
    Note over LDS: Calculate focus window<br/>center_page = (1545 / 100) + 1 = 16
    
    LDS->>LDS: Determine window pages<br/>[15, 16, 17]
    
    loop For each page in window
        LDS->>DB: load_articles_for_page(page)
        DB-->>LDS: 100 articles per page
    end
    
    Note over LDS: Total: 300 articles in window
    
    LDS->>DB: load_all_structure_components()
    DB-->>LDS: All structure (cached)
    
    LDS->>LDS: filter_structure_for_display()<br/>Non-cumulative, strict range
    
    LDS->>LSB: build(components, go_to_position: 1545)
    activate LSB
    
    LSB->>LSB: Build interleaved stream
    LSB->>LSB: Mark target article<br/>go_to_article index
    
    LSB-->>LDS: Stream with 300 articles<br/>+ go_to_article marker
    deactivate LSB
    
    LDS->>LDS: Set focus_mode_active: true
    LDS->>LDS: Build chunk_metadata<br/>pages_included: [15, 16, 17]
    
    LDS-->>C: ServiceResult with focus window
    deactivate LDS
    
    C->>C: Extract stream and go_to_article
    
    C-->>U: Render with scroll-to-article<br/>JavaScript scrolls to target
    deactivate C
    
    Note over U: User sees article 1545<br/>with surrounding context
```

---

## 🗄️ Database Architecture

### Articles Table Schema

```mermaid
erDiagram
    ARTICLES {
        bigint id PK
        string number
        text body
        text body_tsv "Materialized tsvector"
        integer position
        integer law_id FK
        datetime created_at
        datetime updated_at
    }
    
    LAWS {
        bigint id PK
        string name
        text description
        integer cached_articles_count
    }
    
    BOOKS {
        bigint id PK
        string number
        text body
        integer position
        integer law_id FK
    }
    
    TITLES {
        bigint id PK
        string number
        text body
        integer position
        integer law_id FK
    }
    
    CHAPTERS {
        bigint id PK
        string number
        text body
        integer position
        integer law_id FK
    }
    
    SECTIONS {
        bigint id PK
        string number
        text body
        integer position
        integer law_id FK
    }
    
    SUBSECTIONS {
        bigint id PK
        string number
        text body
        integer position
        integer law_id FK
    }
    
    ARTICLES ||--o{ LAWS : "belongs_to"
    BOOKS ||--o{ LAWS : "belongs_to"
    TITLES ||--o{ LAWS : "belongs_to"
    CHAPTERS ||--o{ LAWS : "belongs_to"
    SECTIONS ||--o{ LAWS : "belongs_to"
    SUBSECTIONS ||--o{ LAWS : "belongs_to"
```

### GIN Index Structure

```mermaid
graph TB
    subgraph "PostgreSQL GIN Index: index_articles_on_body_tsv_gin"
        direction TB
        
        Root[GIN Index Root<br/>Entry Tree]
        
        Root --> Token1["Token: 'codigo'<br/>Posting List"]
        Root --> Token2["Token: 'civil'<br/>Posting List"]
        Root --> Token3["Token: 'ley'<br/>Posting List"]
        Root --> Token4["Token: 'justicia'<br/>Posting List"]
        Root --> Token5["Token: 'articulo'<br/>Posting List"]
        Root --> More["... thousands more tokens ..."]
        
        Token1 --> PL1["Article IDs:<br/>[1, 15, 47, 98, 142, 234, ...]"]
        Token2 --> PL2["Article IDs:<br/>[1, 15, 20, 47, 92, 156, ...]"]
        Token3 --> PL3["Article IDs:<br/>[2, 15, 47, 102, 234, 567, ...]"]
        Token4 --> PL4["Article IDs:<br/>[15, 23, 45, 102, 189, 345, ...]"]
        Token5 --> PL5["Article IDs:<br/>[2, 15, 23, 45, 89, 123, ...]"]
        
        Search[Search Query:<br/>'ley justicia']
        Search -.->|1. Lookup| Token3
        Search -.->|2. Lookup| Token4
        
        Token3 -.->|3. Get IDs| Bitmap1["Bitmap:<br/>0101001001..."]
        Token4 -.->|4. Get IDs| Bitmap2["Bitmap:<br/>0001010001..."]
        
        Bitmap1 --> AND[5. Bitmap AND Operation]
        Bitmap2 --> AND
        
        AND --> Result["Result IDs:<br/>[15, 102]<br/>Articles with BOTH terms"]
        
        Result --> Heap[6. Heap Fetch<br/>Get actual article data]
        Heap --> Final[7. Return Results<br/>Time: 11ms ⚡]
        
        style Root fill:#e3f2fd,stroke:#2196f3,color:#000000
        style Token3 fill:#fff3cd,stroke:#ffc107,color:#000000
        style Token4 fill:#fff3cd,stroke:#ffc107,color:#000000
        style AND fill:#d4edda,stroke:#28a745,color:#000000
        style Final fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---

## 🏗️ Service Layer Architecture

### Service Class Hierarchy

```mermaid
classDiagram
    direction TB
    
    class ApplicationService {
        <<Base Class>>
        +call()* abstract
        #success(data, metadata) ServiceResult
        #failure(errors, metadata) ServiceResult
    }
    
    class ServiceResult {
        +data Hash
        +errors Array
        +metadata Hash
        +success?() boolean
        +failure?() boolean
        +error_message() String
        +[](key) Object
    }
    
    class LawDisplayConfig {
        <<Module>>
        +DEFAULT_CHUNK_SIZE 100
        +CHUNK_SIZES Hash
        +ACCESS_LIMITS Hash
        +SEARCH_CONFIG Hash
        +CACHE_CONFIG Hash
        +chunk_size_for(user, context) Integer
        +access_limit_for(user) Integer
    }
    
    class LawDisplayService {
        -@law Law
        -@user User
        -@params Hash
        -@page Integer
        -@chunk_size Integer
        +initialize(law, user, params)
        +call() ServiceResult
        -search_request?() boolean
        -article_filter_request?() boolean
        -chunked_request?() boolean
        -process_search_request(display_data)
        -process_article_filter_request(display_data)
        -process_normal_display_request(display_data)
        -build_chunked_law_stream() Hash
        -load_chunked_articles() Relation
        -filter_structure_for_display() Hash
        -calculate_chunk_metadata() Hash
        -apply_access_limitations(display_data)
    }
    
    class LawStreamBuilder {
        -@law Law
        -@components Hash
        -@go_to_position Integer
        -@book_iterator Integer
        -@title_iterator Integer
        -@chapter_iterator Integer
        -@article_iterator Integer
        +initialize(law, components, go_to_position)
        +build() Hash
        -should_add_book?() boolean
        -should_add_title?() boolean
        -should_add_chapter?() boolean
        -should_add_article?() boolean
        -add_book_to_stream()
        -add_title_to_stream()
        -add_article_to_stream()
        -only_articles_in_stream?() boolean
    }
    
    ApplicationService <|-- LawDisplayService : inherits
    LawDisplayService --> ServiceResult : returns
    LawDisplayService ..> LawDisplayConfig : includes
    LawDisplayService --> LawStreamBuilder : uses
    LawStreamBuilder --> ServiceResult : returns
    
    note for LawDisplayService "Main orchestrator:\n- Request routing\n- Component loading\n- Access control\n- Result assembly"
    
    note for LawStreamBuilder "Stream builder:\n- Position-based sorting\n- Component interleaving\n- Index generation\n- Go-to-article marking"
    
    note for ServiceResult "Standard result:\n- Success/failure state\n- Data payload\n- Error messages\n- Metadata"
```

---

### Service Interaction Flow

```mermaid
graph TB
    subgraph "Controller Layer"
        AC[ApplicationController<br/>get_raw_law method<br/>25 lines]
    end
    
    subgraph "Service Layer Components"
        LDS[LawDisplayService<br/>522 lines]
        LSB[LawStreamBuilder<br/>258 lines]
        SR[ServiceResult]
        Config[LawDisplayConfig]
    end
    
    subgraph "Model Layer"
        Law[Law Model]
        Article[Article Model]
        Structure[Structure Models]
    end
    
    subgraph "Database Layer"
        DB[(PostgreSQL)]
    end
    
    AC -->|1. Call| LDS
    LDS -->|2. Initialize| Config
    LDS -->|3. Query| Law
    LDS -->|4. Query| Article
    LDS -->|5. Query| Structure
    
    Law --> DB
    Article --> DB
    Structure --> DB
    
    LDS -->|6. Build stream| LSB
    LSB -->|7. Interleave| LSB
    LSB -->|8. Return result| LDS
    
    LDS -->|9. Create result| SR
    SR -->|10. Return| AC
    
    AC -->|11. Extract data| AC
    AC -->|12. Render| View[View Layer]
    
    style LDS fill:#d4edda,stroke:#28a745,color:#000000
    style LSB fill:#d4edda,stroke:#28a745,color:#000000
    style SR fill:#d4edda,stroke:#28a745,color:#000000
```

---

## 🔍 Data Flow Examples

### Example 1: Search Query Performance

```mermaid
graph TB
    subgraph "User Query: 'justicia constitutional'"
        direction TB
        
        Input[User Input<br/>'justicia constitutional']
        
        Input --> Parse[pg_search parses query]
        Parse --> TSQuery[plainto_tsquery<br/>'justicia' & 'constitutional']
        
        TSQuery --> GIN[GIN Index Lookup]
        
        GIN --> L1[Lookup 'justicia'<br/>→ [15, 23, 45, 102, 189, ...]]
        GIN --> L2[Lookup 'constitutional'<br/>→ [15, 67, 102, 145, 234, ...]]
        
        L1 --> Bitmap[Bitmap AND Operation]
        L2 --> Bitmap
        
        Bitmap --> Match[Matched Articles:<br/>[15, 102]<br/>Both terms present]
        
        Match --> Fetch[Bitmap Heap Scan<br/>Fetch article data]
        
        Fetch --> Highlight[Apply Highlighting<br/>with pg_search]
        
        Highlight --> Result[Return 2 Articles<br/>Time: 11ms ⚡]
        
        style GIN fill:#d4edda,stroke:#28a745,color:#000000
        style Bitmap fill:#d4edda,stroke:#28a745,color:#000000
        style Result fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---

### Example 2: Chunked Law Loading

```mermaid
graph TB
    subgraph "Loading Código Civil (2,369 articles)"
        direction TB
        
        Request[User Requests Law<br/>GET /laws/81]
        
        Request --> Check{What type?}
        
        Check -->|No params| FirstChunk[Load First Chunk<br/>Page 1]
        Check -->|?page=2| NextChunk[Load Next Chunk<br/>Page 2]
        Check -->|?query=X| Search[Search Request]
        Check -->|?articles=X| Focus[Focus Mode]
        
        FirstChunk --> LoadStructure[Load ALL Structure<br/>Books, Titles, Chapters<br/>Fast: indexed by law_id]
        
        FirstChunk --> LoadArticles1[Load Articles<br/>LIMIT 100 OFFSET 0<br/>Articles 1-100]
        
        LoadStructure --> Filter1[Filter Structure<br/>Position ≤ 100<br/>Cumulative]
        LoadArticles1 --> Filter1
        
        Filter1 --> Build1[Build Stream<br/>Interleave components]
        
        Build1 --> Meta1[Chunk Metadata<br/>page: 1/24<br/>has_more: true]
        
        Meta1 --> Render1[Render View<br/>+ Turbo Frame setup]
        
        NextChunk --> LoadArticles2[Load Articles<br/>LIMIT 100 OFFSET 100<br/>Articles 101-200]
        
        NextChunk --> Filter2[Filter Structure<br/>101 ≤ Position ≤ 200<br/>Non-cumulative]
        LoadArticles2 --> Filter2
        
        Filter2 --> Build2[Build Stream<br/>Only NEW components]
        
        Build2 --> Meta2[Chunk Metadata<br/>page: 2/24<br/>has_more: true]
        
        Meta2 --> Append[Turbo Frame Append<br/>Seamless addition]
        
        style LoadStructure fill:#fff3cd,stroke:#ffc107,color:#000000
        style Filter1 fill:#d4edda,stroke:#28a745,color:#000000
        style Filter2 fill:#d4edda,stroke:#28a745,color:#000000
        style Build1 fill:#d4edda,stroke:#28a745,color:#000000
        style Build2 fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---

### Example 3: Focus Mode Window

```mermaid
graph TB
    subgraph "Jump to Article 1545 in Código Civil"
        direction TB
        
        Request[User Requests<br/>?articles=1545]
        
        Request --> Find[Find Article<br/>number LIKE '%1545%']
        
        Find --> Cache[Get from Manifest Cache<br/>global_index: 1545]
        
        Cache --> CalcPage[Calculate Center Page<br/>center = 1545 / 100 + 1 = 16]
        
        CalcPage --> Window[Determine Window<br/>pages [15, 16, 17]]
        
        Window --> Load15[Load Page 15<br/>Articles 1401-1500]
        Window --> Load16[Load Page 16<br/>Articles 1501-1600]
        Window --> Load17[Load Page 17<br/>Articles 1601-1700]
        
        Load15 --> Combine[Combine Articles<br/>Total: 300 articles]
        Load16 --> Combine
        Load17 --> Combine
        
        Combine --> FilterStruct[Filter Structure<br/>1401 ≤ pos ≤ 1700<br/>Non-cumulative, strict]
        
        FilterStruct --> BuildStream[Build Stream<br/>go_to_position: 1545]
        
        BuildStream --> Mark[Mark Target Article<br/>go_to_article index]
        
        Mark --> Metadata[Focus Metadata<br/>pages: [15,16,17]<br/>focus_mode: true]
        
        Metadata --> Render[Render + Scroll<br/>JavaScript scrolls to 1545]
        
        style Cache fill:#fff3cd,stroke:#ffc107,color:#000000
        style Combine fill:#d4edda,stroke:#28a745,color:#000000
        style BuildStream fill:#d4edda,stroke:#28a745,color:#000000
        style Render fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---

## 🎨 Component Interactions

### Service Result Pattern

```mermaid
stateDiagram-v2
    [*] --> Initialization: Service.call()
    
    Initialization --> Processing: Begin execution
    
    Processing --> Success: Operation succeeds
    Processing --> Failure: Error occurs
    
    Success --> ResultCreation: ServiceResult.success(data)
    Failure --> ResultCreation: ServiceResult.failure(errors)
    
    ResultCreation --> Controller: Return to controller
    
    Controller --> SuccessPath: result.success?
    Controller --> FailurePath: result.failure?
    
    SuccessPath --> ExtractData: result.data
    SuccessPath --> RenderView: Display content
    
    FailurePath --> LogError: result.error_message
    FailurePath --> SafeDefaults: Set fallback values
    
    RenderView --> [*]
    SafeDefaults --> [*]
    
    note right of ResultCreation
        Consistent interface:
        - success? / failure?
        - data / errors
        - metadata
    end note
```

---

### Stream Building Algorithm

```mermaid
graph TB
    subgraph "Position-Based Stream Building"
        direction TB
        
        Start[Start Stream Building]
        
        Start --> Init[Initialize:<br/>- Counters for each type<br/>- Result arrays<br/>- Total stream size]
        
        Init --> Loop{More<br/>components?}
        
        Loop -->|Yes| CheckType{Which type<br/>has lowest<br/>position?}
        
        CheckType -->|Book| AddBook[Add Book<br/>Increment book counter<br/>Add to index]
        CheckType -->|Title| AddTitle[Add Title<br/>Increment title counter<br/>Add to index]
        CheckType -->|Chapter| AddChapter[Add Chapter<br/>Increment chapter counter<br/>Add to index]
        CheckType -->|Section| AddSection[Add Section<br/>Increment section counter<br/>Add to index]
        CheckType -->|Subsection| AddSubsection[Add Subsection<br/>Increment subsection counter<br/>Add to index]
        CheckType -->|Article| AddArticle[Add Article<br/>Increment article counter<br/>Check go_to_position]
        
        AddBook --> Loop
        AddTitle --> Loop
        AddChapter --> Loop
        AddSection --> Loop
        AddSubsection --> Loop
        AddArticle --> Loop
        
        Loop -->|No| Check{Only<br/>articles?}
        
        Check -->|Yes| SetFlag[has_articles_only = true]
        Check -->|No| KeepFalse[has_articles_only = false]
        
        SetFlag --> Return[Return Result:<br/>- stream<br/>- index_items<br/>- go_to_article<br/>- has_articles_only]
        KeepFalse --> Return
        
        Return --> End[End]
        
        style CheckType fill:#fff3cd,stroke:#ffc107,color:#000000
        style AddBook fill:#e3f2fd,stroke:#2196f3,color:#000000
        style AddTitle fill:#e3f2fd,stroke:#2196f3,color:#000000
        style AddChapter fill:#e3f2fd,stroke:#2196f3,color:#000000
        style AddArticle fill:#d4edda,stroke:#28a745,color:#000000
        style Return fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---

## 📊 Performance Characteristics

### Query Performance Comparison

```mermaid
graph LR
    subgraph "Before Optimization"
        Q1[Search Query] --> Seq1[Sequential Scan<br/>Read ALL rows]
        Seq1 --> Comp1[For Each Row:<br/>unaccent<br/>coalesce<br/>to_tsvector]
        Comp1 --> Match1[Compare to search]
        Match1 --> Result1[Return results<br/>Time: 8,763ms 🐌]
        
        style Seq1 fill:#f8d7da,stroke:#dc3545,color:#000000
        style Comp1 fill:#f8d7da,stroke:#dc3545,color:#000000
        style Result1 fill:#f8d7da,stroke:#dc3545,color:#000000
    end
    
    subgraph "After Optimization"
        Q2[Search Query] --> GIN2[GIN Index Lookup<br/>O log N]
        GIN2 --> Bitmap2[Bitmap Operations<br/>Fast set operations]
        Bitmap2 --> Heap2[Heap Fetch<br/>Only matching rows]
        Heap2 --> Result2[Return results<br/>Time: 11ms ⚡]
        
        style GIN2 fill:#d4edda,stroke:#28a745,color:#000000
        style Bitmap2 fill:#d4edda,stroke:#28a745,color:#000000
        style Result2 fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---

### Chunk Loading Performance

```mermaid
gantt
    title Law Loading Performance (Código Civil - 2,369 articles)
    dateFormat X
    axisFormat %Ls
    
    section Before (Monolithic)
    Load ALL 2,369 articles : done, before, 0, 50000
    Complex stream building : done, before2, 50000, 51000
    
    section After Phase 1
    Load ALL 2,369 articles : done, phase1, 0, 50000
    Optimized stream building : done, phase1b, 50000, 51000
    
    section After Phase 2 (Target)
    Load first 100 articles : crit, phase2, 0, 1000
    Build stream (100) : crit, phase2b, 1000, 2000
    AJAX chunk 2 (100) : phase2c, 2000, 2500
    AJAX chunk 3 (100) : phase2d, 2500, 3000
    Background chunks : phase2e, 3000, 10000
```

---

## 🔐 Access Control Flow

```mermaid
graph TB
    subgraph "User Access Control"
        Request[User Request]
        
        Request --> CheckAuth{User<br/>authenticated?}
        
        CheckAuth -->|No| BasicLimit[Apply Basic Limit<br/>5 articles max<br/>service layer]
        CheckAuth -->|Yes| CheckPremium{Premium<br/>user?}
        
        CheckPremium -->|No| CheckLaw{Law<br/>accessible?}
        CheckPremium -->|Yes| FullAccess[Full Access<br/>All articles<br/>All features]
        
        CheckLaw -->|Yes| LimitedAccess[Limited Access<br/>First 5 articles]
        CheckLaw -->|No| Blocked[Access Denied<br/>Upgrade prompt]
        
        BasicLimit --> ServiceLimit[Service: stream.take 5]
        LimitedAccess --> ControllerLimit[Controller: stream.take 5]
        
        ServiceLimit --> Display[Display Limited]
        ControllerLimit --> Display
        FullAccess --> DisplayFull[Display Full]
        Blocked --> DisplayBlocked[Display Message]
        
        style BasicLimit fill:#fff3cd,stroke:#ffc107,color:#000000
        style LimitedAccess fill:#fff3cd,stroke:#ffc107,color:#000000
        style FullAccess fill:#d4edda,stroke:#28a745,color:#000000
        style Blocked fill:#f8d7da,stroke:#dc3545,color:#000000
    end
```

---

## 📈 Scalability Considerations

### Database Indexing Strategy

```
Articles Table Indexes:
├── index_articles_on_body_tsv_gin (GIN)
│   Purpose: Full-text search
│   Size: ~50-100 MB
│   Usage: Every search query
│   Performance: O(log N) lookup
│
├── index_articles_on_law_id (B-tree)
│   Purpose: Law filtering
│   Size: ~5-10 MB
│   Usage: Every law display
│   Performance: O(log N) lookup
│
├── index_articles_on_position (B-tree)
│   Purpose: Sorting, chunking
│   Size: ~5-10 MB
│   Usage: Every request
│   Performance: O(log N) + sequential scan
│
└── index_articles_on_number (B-tree)
    Purpose: Article lookup
    Size: ~5-10 MB
    Usage: Focus mode, direct links
    Performance: O(log N) lookup
```

### Caching Strategy

```mermaid
graph TB
    subgraph "Multi-Level Caching"
        Request[User Request]
        
        Request --> L1{Manifest<br/>Cache?}
        
        L1 -->|Hit| M1[Return Cached<br/>Metadata<br/>TTL: 1 hour]
        L1 -->|Miss| L2{Component<br/>Cache?}
        
        L2 -->|Hit| M2[Return Cached<br/>Structure<br/>TTL: 1 hour]
        L2 -->|Miss| DB[Database Query]
        
        DB --> Store[Store in Cache<br/>With compression]
        Store --> M3[Return Fresh Data]
        
        M1 --> Fast[⚡ Fast Response<br/><50ms]
        M2 --> Medium[⚙️ Medium Response<br/><200ms]
        M3 --> Slow[💾 DB Response<br/><500ms]
        
        style M1 fill:#d4edda,stroke:#28a745,color:#000000
        style M2 fill:#fff3cd,stroke:#ffc107,color:#000000
        style Fast fill:#d4edda,stroke:#28a745,color:#000000
    end
```

---


---

## 📚 Quick Reference

### Key Files

**Service Layer:**
- `app/services/application_service.rb` - Base service (55 lines)
- `app/services/service_result.rb` - Result pattern (85 lines)
- `app/services/law_display_service.rb` - Main orchestrator (546 lines)
- `app/services/law_stream_builder.rb` - Stream builder (258 lines)
- `app/services/concerns/law_display_config.rb` - Configuration (60 lines)
- `app/services/laws/manifest_builder.rb` - Hierarchy builder (230 lines)
- `app/services/laws/manifest_cache.rb` - Cache layer (80 lines)

**Controllers:**
- `app/controllers/application_controller.rb` - `get_raw_law` method (25 lines)
- `app/controllers/laws_controller.rb` - `show`, `load_chunk`, `manifest` actions

**Frontend (Hotwire):**
- `app/javascript/controllers/law_infinite_scroll_controller.js` - Stimulus: infinite scroll
- `app/javascript/controllers/manifest_loader.js` - Client-side manifest navigation
- `app/views/laws/_law_chunk.html.erb` - Turbo Stream chunk partial
- `app/views/laws/_focus_toolbar.html.erb` - Focus mode toolbar

**Models:**
- `app/models/article.rb` - With pg_search scopes + `tsvector_column: 'body_tsv'`
- `app/models/law.rb` - Law model with `after_commit :warm_manifest_cache`

**Background Jobs:**
- `app/jobs/warm_law_manifest_job.rb` - Warms manifest caches on law create/update

**Migrations:**
- `20251202054830_add_body_tsv_to_articles.rb` - Materialized tsvector
- `20251202070448_remove_legacy_body_gin_index.rb` - Cleanup

### Key Concepts

**GIN Index:** Generalized Inverted Index for fast token lookups  
**TSVector:** PostgreSQL text search vector (tokenized, stemmed)  
**Materialized Column:** Pre-computed values stored permanently  
**Service Result:** Success/failure result pattern  
**Chunked Loading:** Progressive loading in 100-article chunks  
**Focus Mode:** ±1 page window around target for deep navigation  
**Manifest:** Hierarchical structure + article index for client-side O(1) lookups  
**Turbo Streams:** Server-rendered HTML chunks appended via AJAX  

### Performance Numbers (Production — Código Civil, 2,369 articles)

**Law Display:**
- Before: 5,762ms total page load
- After (chunked): 556ms first page (90.3% improvement)

**Search:**
- SQL Time: 8,763ms → 11ms (99% improvement)
- Total Time: 9,215ms → 837ms (91% improvement)
- User Experience: 13-19s → 2-3s (85% improvement)

---

**Document Version:** 2.0  
**Last Updated:** February 2026  
**Status:** Current Production Architecture for Search and Law Display features
