package llama

import (
	"bufio"
	"bytes"
	"strings"
	"testing"
)

// https://github.com/ollama/ollama/issues/7978
const issue7978JSONSchema = `{
  "type": "object",
  "properties": {
    "steps": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "explanation": { "type": "string" },
          "output": { "type": "string" },
          "nested": {
            "type": "object",
            "properties": {
              "deep": { "type": "string" }
            }
          }
        },
        "required": ["explanation", "output"],
        "additionalProperties": false
      }
    },
    "final_answer": { "type": "string" },
    "01_numbered_key": { "type": "string" },
    "numbers": {
      "type": "array",
      "items": { "type": "number" }
    },
    "booleans": {
      "type": "array", 
      "items": { "type": "boolean" }
    },
    "mixed": {
      "type": "array",
      "items": {
        "oneOf": [
          { "type": "string" },
          { "type": "number" },
          { "type": "boolean" }
        ]
      }
    }
  },
  "required": ["steps", "final_answer"],
  "additionalProperties": false
}`

func TestIssue7978(t *testing.T) {
	t.Skip("skipping until grammar ordering is fixed")
	g := SchemaToGrammar([]byte(issue7978JSONSchema))
	if g == nil {
		t.Fatal("failed to convert JSON schema to grammar")
	}

	t.Logf("grammar:\n%s", g)
	t.Log()

	// Verify grammar structure and ordering
	var sawSteps, sawFinalAnswer, saw01Answer, sawNumbers, sawBooleans, sawMixed bool
	var lastSeen string
	s := bufio.NewScanner(bytes.NewReader(g))
	for s.Scan() {
		line := s.Text()
		switch {
		case strings.Contains(line, "steps"):
			sawSteps = true
			lastSeen = "steps"
		case strings.Contains(line, "final_answer"):
			sawFinalAnswer = true
			if lastSeen != "steps" {
				t.Errorf("expected 'steps' immediately before 'final_answer'")
			}
			lastSeen = "final_answer"
		case strings.Contains(line, "01_numbered_key"):
			saw01Answer = true
			if lastSeen != "final_answer" {
				t.Errorf("expected 'final_answer' immediately before '01_numbered_key'")
			}
			lastSeen = "01_numbered_key"
		case strings.Contains(line, "numbers"):
			sawNumbers = true
			if lastSeen != "01_numbered_key" {
				t.Errorf("expected '01_numbered_key' immediately before 'numbers'")
			}
			lastSeen = "numbers"
		case strings.Contains(line, "booleans"):
			sawBooleans = true
			if lastSeen != "numbers" {
				t.Errorf("expected 'numbers' immediately before 'booleans'")
			}
			lastSeen = "booleans"
		case strings.Contains(line, "mixed"):
			sawMixed = true
			if lastSeen != "booleans" {
				t.Errorf("expected 'booleans' immediately before 'mixed'")
			}
			lastSeen = "mixed"
		}
	}

	// Verify required fields are present
	if !sawSteps {
		t.Error("grammar missing 'steps' production")
	}
	if !sawFinalAnswer {
		t.Error("grammar missing 'final_answer' production")
	}

	// Verify optional fields
	if !saw01Answer {
		t.Error("grammar missing '01_answer' production")
	}
	if !sawNumbers {
		t.Error("grammar missing 'numbers' production")
	}
	if !sawBooleans {
		t.Error("grammar missing 'booleans' production")
	}
	if !sawMixed {
		t.Error("grammar missing 'mixed' production")
	}
}

func TestSchemaToGrammer(t *testing.T) {
	cases := []struct {
		schema string
		prefix []byte // nil is check as nil
	}{
		{`invalid`, nil},

		// Simple heuristic/smoke test
		{`{"type":"object"}`, []byte("root ::= object")},
	}

	for _, c := range cases {
		t.Run("x", func(t *testing.T) {
			g := SchemaToGrammar([]byte(c.schema))
			if c.prefix == nil && g != nil {
				t.Fatalf("grammar = %v, want nil", g)
			}
			if !bytes.HasPrefix(g, c.prefix) {
				t.Errorf("grammar = %q, want %q", g, c.prefix)
			}
		})
	}
}
