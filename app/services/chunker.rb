# Splits long text into overlapping chunks.
#
# Overlap matters: if a question's answer spans two chunks, a small overlap
# keeps the boundary context in both, so the vector search can still match.
#
# The previous chunk's tail (OVERLAP chars) carries into the next chunk, and
# sentence breaks are only searched for in the *new* portion — otherwise the
# break point would be re-found inside the overlap and chunks would shrink.
class Chunker
  CHUNK_SIZE = 1500   # characters
  OVERLAP = 200       # characters of context carried from the previous chunk

  class << self
    def call(text)
      normalized = text.gsub(/\s+/, " ").strip
      return [] if normalized.empty?

      chunks = []
      cursor = 0

      while cursor < normalized.length
        slice = normalized[cursor, CHUNK_SIZE]
        break_at = best_break(slice)

        chunks << slice[0, break_at].strip

        # Last chunk reached (either the slice covered the rest of the text,
        # or the break point is at the very end).
        break if cursor + break_at >= normalized.length

        # Carry OVERLAP chars of context into the next chunk; never stall.
        cursor += [ break_at - OVERLAP, 1 ].max
      end

      chunks.reject(&:empty?)
    end

    # Rough token estimate (used for display + budgeting).
    def token_count(text)
      (text.length / 4.0).round
    end

    private

    # Prefer a sentence end (`. ` `! ` `? `) or newline inside the NEW portion
    # of the slice (everything past the overlap); otherwise hard-cut at the limit.
    def best_break(slice)
      new_zone = slice[OVERLAP..] || ""
      boundary = new_zone.rindex(/[.!?\n]/)
      boundary ? OVERLAP + boundary + 1 : slice.length
    end
  end
end
