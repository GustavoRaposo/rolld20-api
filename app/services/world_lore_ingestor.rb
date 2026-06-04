class WorldLoreIngestor
  MAX_CHUNK_CHARS = 1_200
  MIN_CHUNK_CHARS = 60

  def initialize(campaign:, embedder: EmbeddingClient.new)
    @campaign = campaign
    @embedder = embedder
  end

  # Splits lore_text into chunks, generates embeddings, upserts WorldLoreEmbedding records.
  # Returns { total:, added: } counts.
  def call(lore_text)
    chunks = chunk(lore_text)
    added  = chunks.count { |text| upsert_chunk(text) }
    @campaign.update!(world_configured: true)
    { total: chunks.size, added: added }
  end

  private

  def chunk(text)
    paragraphs = text.split(/\n{2,}/).map(&:strip).reject(&:empty?)

    paragraphs.flat_map do |para|
      if para.length <= MAX_CHUNK_CHARS
        [para]
      else
        split_long(para)
      end
    end.select { |c| c.length >= MIN_CHUNK_CHARS }
  end

  def split_long(text)
    sentences = text.scan(/[^.!?]+[.!?]+/).map(&:strip)
    sentences = [text] if sentences.empty?

    chunks  = []
    current = +""

    sentences.each do |sentence|
      if current.length + sentence.length > MAX_CHUNK_CHARS && current.length >= MIN_CHUNK_CHARS
        chunks << current.strip
        current = +""
      end
      current << " " unless current.empty?
      current << sentence
    end

    chunks << current.strip unless current.strip.empty?
    chunks
  end

  # Returns true if a new chunk was created, false if it already existed.
  def upsert_chunk(text)
    id = chunk_id(text)
    return false if @campaign.world_lore_embeddings.exists?(chunk_id: id)

    vector = @embedder.embed(text)
    @campaign.world_lore_embeddings.create!(
      content:   text,
      chunk_id:  id,
      embedding: vector
    )
    true
  end

  def chunk_id(text)
    Digest::SHA256.hexdigest("#{@campaign.id}:#{text}")[0..23]
  end
end
