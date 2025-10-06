# Component Development Guide

## Overview

This comprehensive guide covers component development for the Hugo Template Factory. Components are modular, reusable features that can be integrated into any template, providing functionality like interactive quizzes, analytics tracking, and authentication systems.

## Prerequisites

Before developing components, ensure you have:

- **Hugo Template Factory**: Understanding of build system and templates
- **Hugo knowledge**: Shortcodes, partial templates, configuration
- **JavaScript/TypeScript**: For interactive components
- **YAML/JSON**: For configuration and data structures
- **Node.js**: For build tools and package management

## Component Architecture

Components follow a standardized structure for consistency and interoperability:

```
components/
└── your-component/
    ├── README.md              # Component documentation
    ├── component.yml          # Component metadata
    ├── config.yml            # Default configuration
    ├── layouts/              # Hugo layout templates
    │   ├── shortcodes/       # Component shortcodes
    │   └── partials/         # Reusable template parts
    ├── static/               # Static assets
    │   ├── css/             # Component stylesheets
    │   ├── js/              # JavaScript/TypeScript
    │   └── images/          # Component images
    ├── content/              # Example content
    ├── data/                 # Data files and schemas
    ├── tests/                # Component tests
    └── docs/                 # Detailed documentation
```

## Component Lifecycle

### 1. Planning Phase

Define component requirements and specifications:

```yaml
# component.yml - Component metadata
name: "quiz-engine"
version: "1.0.0"
description: "Interactive quiz system for educational content"
author: "info-tech-io"
license: "Apache-2.0"

# Component requirements
hugo_version: ">=0.120.0"
dependencies:
  - name: "analytics"
    version: ">=2.0.0"
    optional: true

# Component categories
categories:
  - "education"
  - "interactive"
  - "assessment"

# Target templates
compatible_templates:
  - "default"
  - "academic"
  - "educational"
```

### 2. Development Setup

Create component structure:

```bash
# Create component directory
mkdir -p components/quiz-engine/{layouts,static,content,tests,docs}

# Initialize component metadata
cat > components/quiz-engine/component.yml << 'EOF'
name: "quiz-engine"
version: "1.0.0"
description: "Interactive quiz system"
author: "info-tech-io"
license: "Apache-2.0"
EOF

# Create default configuration
cat > components/quiz-engine/config.yml << 'EOF'
quiz_engine:
  theme: "modern"
  progress_tracking: true
  time_limit: 300  # seconds
  retry_attempts: 3
  shuffle_questions: false
  shuffle_options: true
EOF
```

### 3. Implementation Phase

#### Hugo Shortcode Development

Create component shortcodes for content integration:

```go
{{/* layouts/shortcodes/quiz.html */}}
{{- $quiz_id := .Get "id" | default (printf "quiz-%d" now.Unix) -}}
{{- $quiz_file := .Get "file" | default "quiz.yml" -}}
{{- $quiz_data := index .Site.Data.quizzes $quiz_file -}}

<div class="quiz-container" id="{{ $quiz_id }}">
  <div class="quiz-header">
    <h3>{{ $quiz_data.title }}</h3>
    <p>{{ $quiz_data.description }}</p>
  </div>

  <div class="quiz-questions">
    {{- range $index, $question := $quiz_data.questions -}}
    <div class="question" data-question="{{ $index }}">
      <h4>{{ $question.question }}</h4>

      {{- if eq $question.type "single-choice" -}}
        {{- range $opt_index, $option := $question.options -}}
        <label class="option">
          <input type="radio" name="q{{ $index }}" value="{{ $opt_index }}">
          {{ $option }}
        </label>
        {{- end -}}
      {{- else if eq $question.type "multiple-choice" -}}
        {{- range $opt_index, $option := $question.options -}}
        <label class="option">
          <input type="checkbox" name="q{{ $index }}" value="{{ $opt_index }}">
          {{ $option }}
        </label>
        {{- end -}}
      {{- else if eq $question.type "input-field" -}}
        <input type="text" name="q{{ $index }}" placeholder="Enter your answer">
      {{- end -}}
    </div>
    {{- end -}}
  </div>

  <div class="quiz-controls">
    <button id="submit-quiz" data-quiz="{{ $quiz_id }}">Submit Quiz</button>
    <button id="reset-quiz" data-quiz="{{ $quiz_id }}">Reset</button>
  </div>

  <div class="quiz-results" id="results-{{ $quiz_id }}" style="display: none;">
    <div class="score-display"></div>
    <div class="answer-review"></div>
  </div>
</div>

{{- if not .Site.Params.quiz_engine_loaded -}}
  <link rel="stylesheet" href="{{ "css/quiz-engine.css" | relURL }}">
  <script src="{{ "js/quiz-engine.js" | relURL }}"></script>
  {{- .Site.Scratch.Set "quiz_engine_loaded" true -}}
{{- end -}}
```

#### JavaScript Component Logic

Implement interactive functionality:

```typescript
// static/js/quiz-engine.ts
interface QuizQuestion {
  question: string;
  type: 'single-choice' | 'multiple-choice' | 'input-field';
  options?: string[];
  correct: number | number[] | string;
  explanation?: string;
}

interface QuizData {
  title: string;
  description: string;
  questions: QuizQuestion[];
  passing_score?: number;
}

class QuizEngine {
  private quizId: string;
  private quizData: QuizData;
  private userAnswers: Map<number, any> = new Map();
  private startTime: number;

  constructor(quizId: string, quizData: QuizData) {
    this.quizId = quizId;
    this.quizData = quizData;
    this.startTime = Date.now();
    this.initialize();
  }

  private initialize(): void {
    this.setupEventListeners();
    this.loadProgress();
  }

  private setupEventListeners(): void {
    const submitButton = document.getElementById('submit-quiz');
    const resetButton = document.getElementById('reset-quiz');

    submitButton?.addEventListener('click', () => this.submitQuiz());
    resetButton?.addEventListener('click', () => this.resetQuiz());

    // Auto-save answers
    const questions = document.querySelectorAll('.question input');
    questions.forEach(input => {
      input.addEventListener('change', (e) => this.saveAnswer(e));
    });
  }

  private saveAnswer(event: Event): void {
    const input = event.target as HTMLInputElement;
    const questionIndex = parseInt(
      input.closest('.question')?.getAttribute('data-question') || '0'
    );

    if (input.type === 'radio' || input.type === 'text') {
      this.userAnswers.set(questionIndex, input.value);
    } else if (input.type === 'checkbox') {
      const currentAnswers = this.userAnswers.get(questionIndex) || [];
      if (input.checked) {
        currentAnswers.push(input.value);
      } else {
        const index = currentAnswers.indexOf(input.value);
        if (index > -1) currentAnswers.splice(index, 1);
      }
      this.userAnswers.set(questionIndex, currentAnswers);
    }

    this.saveProgress();
  }

  private submitQuiz(): void {
    const results = this.calculateResults();
    this.displayResults(results);
    this.trackCompletion(results);
  }

  private calculateResults(): QuizResults {
    let correctAnswers = 0;
    const totalQuestions = this.quizData.questions.length;
    const questionResults: QuestionResult[] = [];

    this.quizData.questions.forEach((question, index) => {
      const userAnswer = this.userAnswers.get(index);
      const isCorrect = this.checkAnswer(question, userAnswer);

      if (isCorrect) correctAnswers++;

      questionResults.push({
        questionIndex: index,
        userAnswer,
        correctAnswer: question.correct,
        isCorrect,
        explanation: question.explanation
      });
    });

    const score = Math.round((correctAnswers / totalQuestions) * 100);
    const duration = Math.round((Date.now() - this.startTime) / 1000);

    return {
      score,
      correctAnswers,
      totalQuestions,
      duration,
      passed: score >= (this.quizData.passing_score || 70),
      questionResults
    };
  }

  private checkAnswer(question: QuizQuestion, userAnswer: any): boolean {
    switch (question.type) {
      case 'single-choice':
        return parseInt(userAnswer) === question.correct;

      case 'multiple-choice':
        const correctAnswers = Array.isArray(question.correct)
          ? question.correct
          : [question.correct];
        const userAnswers = Array.isArray(userAnswer)
          ? userAnswer.map(a => parseInt(a))
          : [parseInt(userAnswer)];

        return correctAnswers.length === userAnswers.length &&
               correctAnswers.every(a => userAnswers.includes(a));

      case 'input-field':
        const correctText = question.correct as string;
        return userAnswer.toLowerCase().trim() === correctText.toLowerCase().trim();

      default:
        return false;
    }
  }

  private displayResults(results: QuizResults): void {
    const resultsContainer = document.getElementById(`results-${this.quizId}`);
    if (!resultsContainer) return;

    resultsContainer.innerHTML = `
      <div class="score-display ${results.passed ? 'passed' : 'failed'}">
        <h3>Quiz Complete!</h3>
        <div class="score">${results.score}%</div>
        <div class="details">
          ${results.correctAnswers} out of ${results.totalQuestions} correct
        </div>
        <div class="duration">
          Completed in ${Math.floor(results.duration / 60)}:${(results.duration % 60).toString().padStart(2, '0')}
        </div>
      </div>

      <div class="answer-review">
        <h4>Answer Review</h4>
        ${results.questionResults.map((result, index) => `
          <div class="question-result ${result.isCorrect ? 'correct' : 'incorrect'}">
            <div class="question-text">
              ${this.quizData.questions[index].question}
            </div>
            <div class="answer-status">
              ${result.isCorrect ? '✅ Correct' : '❌ Incorrect'}
            </div>
            ${result.explanation ? `
              <div class="explanation">
                <strong>Explanation:</strong> ${result.explanation}
              </div>
            ` : ''}
          </div>
        `).join('')}
      </div>
    `;

    resultsContainer.style.display = 'block';
  }

  private saveProgress(): void {
    const progress = {
      quizId: this.quizId,
      answers: Object.fromEntries(this.userAnswers),
      timestamp: Date.now()
    };

    localStorage.setItem(`quiz_progress_${this.quizId}`, JSON.stringify(progress));
  }

  private loadProgress(): void {
    const saved = localStorage.getItem(`quiz_progress_${this.quizId}`);
    if (!saved) return;

    try {
      const progress = JSON.parse(saved);
      this.userAnswers = new Map(Object.entries(progress.answers));

      // Restore form state
      this.userAnswers.forEach((answer, questionIndex) => {
        const question = document.querySelector(`[data-question="${questionIndex}"]`);
        if (!question) return;

        if (Array.isArray(answer)) {
          // Multiple choice
          answer.forEach(value => {
            const checkbox = question.querySelector(`input[value="${value}"]`) as HTMLInputElement;
            if (checkbox) checkbox.checked = true;
          });
        } else {
          // Single choice or text input
          const input = question.querySelector(`input[value="${answer}"], input[type="text"]`) as HTMLInputElement;
          if (input) {
            if (input.type === 'text') {
              input.value = answer;
            } else {
              input.checked = true;
            }
          }
        }
      });
    } catch (error) {
      console.warn('Failed to load quiz progress:', error);
    }
  }

  private trackCompletion(results: QuizResults): void {
    // Integration with analytics component
    if (window.analytics && window.analytics.track) {
      window.analytics.track('Quiz Completed', {
        quiz_id: this.quizId,
        score: results.score,
        duration: results.duration,
        passed: results.passed
      });
    }

    // Custom event for other integrations
    window.dispatchEvent(new CustomEvent('quiz:completed', {
      detail: { quizId: this.quizId, results }
    }));
  }
}

// Auto-initialize quizzes on page load
document.addEventListener('DOMContentLoaded', () => {
  const quizContainers = document.querySelectorAll('.quiz-container');

  quizContainers.forEach(container => {
    const quizId = container.id;
    // Quiz data would be embedded or loaded via AJAX
    // For now, assuming it's available globally
    const quizData = window.quizData?.[quizId];

    if (quizData) {
      new QuizEngine(quizId, quizData);
    }
  });
});

// Type definitions
interface QuestionResult {
  questionIndex: number;
  userAnswer: any;
  correctAnswer: any;
  isCorrect: boolean;
  explanation?: string;
}

interface QuizResults {
  score: number;
  correctAnswers: number;
  totalQuestions: number;
  duration: number;
  passed: boolean;
  questionResults: QuestionResult[];
}
```

#### CSS Styling

Create responsive, accessible styles:

```scss
// static/css/quiz-engine.scss
.quiz-container {
  max-width: 800px;
  margin: 2rem auto;
  padding: 1.5rem;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  background: #ffffff;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

  @media (prefers-color-scheme: dark) {
    background: #1a1d21;
    border-color: #30363d;
    color: #f0f6fc;
  }

  .quiz-header {
    margin-bottom: 2rem;
    text-align: center;

    h3 {
      margin: 0 0 0.5rem 0;
      color: #0969da;
      font-size: 1.5rem;

      @media (prefers-color-scheme: dark) {
        color: #58a6ff;
      }
    }

    p {
      margin: 0;
      color: #656d76;
      font-size: 1rem;

      @media (prefers-color-scheme: dark) {
        color: #8b949e;
      }
    }
  }

  .quiz-questions {
    .question {
      margin-bottom: 2rem;
      padding: 1.5rem;
      background: #f6f8fa;
      border-radius: 6px;
      border-left: 4px solid #0969da;

      @media (prefers-color-scheme: dark) {
        background: #21262d;
        border-left-color: #58a6ff;
      }

      h4 {
        margin: 0 0 1rem 0;
        color: #24292f;
        font-size: 1.1rem;
        font-weight: 600;

        @media (prefers-color-scheme: dark) {
          color: #f0f6fc;
        }
      }

      .option {
        display: block;
        margin: 0.5rem 0;
        padding: 0.75rem;
        background: #ffffff;
        border: 1px solid #d0d7de;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s ease;

        @media (prefers-color-scheme: dark) {
          background: #0d1117;
          border-color: #30363d;
          color: #f0f6fc;
        }

        &:hover {
          background: #f3f4f6;
          border-color: #0969da;

          @media (prefers-color-scheme: dark) {
            background: #161b22;
            border-color: #58a6ff;
          }
        }

        input {
          margin-right: 0.5rem;
          accent-color: #0969da;
        }

        input[type="text"] {
          display: block;
          width: 100%;
          margin: 0.5rem 0 0 0;
          padding: 0.5rem;
          border: 1px solid #d0d7de;
          border-radius: 4px;
          font-size: 1rem;

          @media (prefers-color-scheme: dark) {
            background: #0d1117;
            border-color: #30363d;
            color: #f0f6fc;
          }

          &:focus {
            outline: none;
            border-color: #0969da;
            box-shadow: 0 0 0 3px rgba(9, 105, 218, 0.1);

            @media (prefers-color-scheme: dark) {
              border-color: #58a6ff;
              box-shadow: 0 0 0 3px rgba(88, 166, 255, 0.1);
            }
          }
        }
      }
    }
  }

  .quiz-controls {
    display: flex;
    gap: 1rem;
    justify-content: center;
    margin: 2rem 0;

    button {
      padding: 0.75rem 1.5rem;
      border: none;
      border-radius: 6px;
      font-size: 1rem;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;

      &#submit-quiz {
        background: #1f883d;
        color: white;

        &:hover {
          background: #1a7f37;
        }

        &:active {
          background: #166f2c;
        }
      }

      &#reset-quiz {
        background: #f6f8fa;
        color: #24292f;
        border: 1px solid #d0d7de;

        @media (prefers-color-scheme: dark) {
          background: #21262d;
          color: #f0f6fc;
          border-color: #30363d;
        }

        &:hover {
          background: #f3f4f6;

          @media (prefers-color-scheme: dark) {
            background: #30363d;
          }
        }
      }
    }
  }

  .quiz-results {
    margin-top: 2rem;
    padding: 1.5rem;
    background: #f6f8fa;
    border-radius: 6px;

    @media (prefers-color-scheme: dark) {
      background: #21262d;
    }

    .score-display {
      text-align: center;
      margin-bottom: 2rem;
      padding: 1.5rem;
      border-radius: 6px;

      &.passed {
        background: #dafbe1;
        border: 1px solid #1f883d;

        @media (prefers-color-scheme: dark) {
          background: rgba(31, 136, 61, 0.15);
          border-color: #238636;
        }

        h3 {
          color: #1f883d;

          @media (prefers-color-scheme: dark) {
            color: #3fb950;
          }
        }
      }

      &.failed {
        background: #ffebe9;
        border: 1px solid #cf222e;

        @media (prefers-color-scheme: dark) {
          background: rgba(207, 34, 46, 0.15);
          border-color: #da3633;
        }

        h3 {
          color: #cf222e;

          @media (prefers-color-scheme: dark) {
            color: #f85149;
          }
        }
      }

      h3 {
        margin: 0 0 1rem 0;
        font-size: 1.5rem;
      }

      .score {
        font-size: 3rem;
        font-weight: bold;
        margin: 0.5rem 0;
      }

      .details {
        font-size: 1.1rem;
        margin: 0.5rem 0;
      }

      .duration {
        font-size: 1rem;
        color: #656d76;

        @media (prefers-color-scheme: dark) {
          color: #8b949e;
        }
      }
    }

    .answer-review {
      h4 {
        margin: 0 0 1rem 0;
        color: #24292f;

        @media (prefers-color-scheme: dark) {
          color: #f0f6fc;
        }
      }

      .question-result {
        margin: 1rem 0;
        padding: 1rem;
        border-radius: 6px;
        border-left: 4px solid;

        &.correct {
          background: #dafbe1;
          border-left-color: #1f883d;

          @media (prefers-color-scheme: dark) {
            background: rgba(31, 136, 61, 0.15);
            border-left-color: #238636;
          }
        }

        &.incorrect {
          background: #ffebe9;
          border-left-color: #cf222e;

          @media (prefers-color-scheme: dark) {
            background: rgba(207, 34, 46, 0.15);
            border-left-color: #da3633;
          }
        }

        .question-text {
          font-weight: 500;
          margin-bottom: 0.5rem;
        }

        .answer-status {
          font-size: 0.9rem;
          margin-bottom: 0.5rem;
        }

        .explanation {
          font-size: 0.9rem;
          color: #656d76;
          margin-top: 0.5rem;
          padding-top: 0.5rem;
          border-top: 1px solid #d0d7de;

          @media (prefers-color-scheme: dark) {
            color: #8b949e;
            border-top-color: #30363d;
          }
        }
      }
    }
  }
}

// Accessibility improvements
@media (prefers-reduced-motion: reduce) {
  .quiz-container * {
    transition: none !important;
    animation: none !important;
  }
}

// High contrast mode support
@media (prefers-contrast: high) {
  .quiz-container {
    border-width: 2px;

    .question {
      border-left-width: 6px;
    }

    .option {
      border-width: 2px;
    }
  }
}

// Print styles
@media print {
  .quiz-container {
    border: 1px solid #000;

    .quiz-controls {
      display: none;
    }

    .quiz-results {
      page-break-inside: avoid;
    }
  }
}
```

### 4. Configuration Management

Define component configuration schema:

```yaml
# config.yml - Default component configuration
quiz_engine:
  # Visual theme
  theme: "modern"                    # modern, classic, minimal

  # Functionality
  progress_tracking: true            # Save progress to localStorage
  time_limit: 300                   # Time limit in seconds (0 = no limit)
  retry_attempts: 3                 # Number of retry attempts allowed
  shuffle_questions: false          # Randomize question order
  shuffle_options: true             # Randomize answer options

  # Scoring
  passing_score: 70                 # Percentage required to pass
  show_score: true                  # Display score to user
  show_correct_answers: true        # Show correct answers after submission
  show_explanations: true           # Show answer explanations

  # Analytics integration
  track_events: true                # Send events to analytics
  track_detailed_answers: false     # Track individual answer choices

  # Accessibility
  high_contrast: false              # Enable high contrast mode
  keyboard_navigation: true         # Enable keyboard navigation
  screen_reader_support: true       # Enhanced screen reader support

  # Advanced features
  question_bank: false              # Use question banks for randomization
  adaptive_difficulty: false       # Adjust difficulty based on performance
  collaborative_mode: false        # Allow multiple users to take quiz together
```

### 5. Testing Strategy

Create comprehensive tests for component functionality:

```typescript
// tests/quiz-engine.test.ts
import { QuizEngine } from '../static/js/quiz-engine';

describe('QuizEngine', () => {
  let mockQuizData: QuizData;
  let container: HTMLElement;

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = `
      <div class="quiz-container" id="test-quiz">
        <div class="quiz-questions">
          <div class="question" data-question="0">
            <input type="radio" name="q0" value="0">
            <input type="radio" name="q0" value="1">
          </div>
        </div>
        <button id="submit-quiz" data-quiz="test-quiz">Submit</button>
        <button id="reset-quiz" data-quiz="test-quiz">Reset</button>
        <div id="results-test-quiz"></div>
      </div>
    `;

    mockQuizData = {
      title: "Test Quiz",
      description: "A test quiz",
      questions: [
        {
          question: "What is 2+2?",
          type: "single-choice",
          options: ["3", "4", "5"],
          correct: 1,
          explanation: "2+2 equals 4"
        }
      ]
    };

    container = document.getElementById('test-quiz')!;
  });

  afterEach(() => {
    document.body.innerHTML = '';
    localStorage.clear();
  });

  test('initializes correctly', () => {
    const quiz = new QuizEngine('test-quiz', mockQuizData);
    expect(quiz).toBeDefined();
  });

  test('saves answers correctly', () => {
    const quiz = new QuizEngine('test-quiz', mockQuizData);
    const radioButton = document.querySelector('input[value="1"]') as HTMLInputElement;

    radioButton.checked = true;
    radioButton.dispatchEvent(new Event('change'));

    const savedProgress = localStorage.getItem('quiz_progress_test-quiz');
    expect(savedProgress).toBeTruthy();

    const progress = JSON.parse(savedProgress!);
    expect(progress.answers['0']).toBe('1');
  });

  test('calculates score correctly', () => {
    const quiz = new QuizEngine('test-quiz', mockQuizData);

    // Simulate correct answer
    const radioButton = document.querySelector('input[value="1"]') as HTMLInputElement;
    radioButton.checked = true;
    radioButton.dispatchEvent(new Event('change'));

    const submitButton = document.getElementById('submit-quiz') as HTMLButtonElement;
    submitButton.click();

    const resultsContainer = document.getElementById('results-test-quiz');
    expect(resultsContainer?.style.display).toBe('block');
    expect(resultsContainer?.innerHTML).toContain('100%');
  });

  test('handles multiple choice questions', () => {
    mockQuizData.questions[0] = {
      question: "Select all even numbers:",
      type: "multiple-choice",
      options: ["1", "2", "3", "4"],
      correct: [1, 3],
      explanation: "2 and 4 are even numbers"
    };

    // Update DOM for multiple choice
    document.body.innerHTML = `
      <div class="quiz-container" id="test-quiz">
        <div class="quiz-questions">
          <div class="question" data-question="0">
            <input type="checkbox" name="q0" value="0">
            <input type="checkbox" name="q0" value="1">
            <input type="checkbox" name="q0" value="2">
            <input type="checkbox" name="q0" value="3">
          </div>
        </div>
        <button id="submit-quiz" data-quiz="test-quiz">Submit</button>
        <div id="results-test-quiz"></div>
      </div>
    `;

    const quiz = new QuizEngine('test-quiz', mockQuizData);

    // Select correct answers
    const checkbox1 = document.querySelector('input[value="1"]') as HTMLInputElement;
    const checkbox3 = document.querySelector('input[value="3"]') as HTMLInputElement;

    checkbox1.checked = true;
    checkbox3.checked = true;
    checkbox1.dispatchEvent(new Event('change'));
    checkbox3.dispatchEvent(new Event('change'));

    const submitButton = document.getElementById('submit-quiz') as HTMLButtonElement;
    submitButton.click();

    const resultsContainer = document.getElementById('results-test-quiz');
    expect(resultsContainer?.innerHTML).toContain('100%');
  });

  test('loads saved progress', () => {
    // Save progress manually
    const progress = {
      quizId: 'test-quiz',
      answers: { '0': '1' },
      timestamp: Date.now()
    };
    localStorage.setItem('quiz_progress_test-quiz', JSON.stringify(progress));

    const quiz = new QuizEngine('test-quiz', mockQuizData);

    // Check if answer was restored
    const radioButton = document.querySelector('input[value="1"]') as HTMLInputElement;
    expect(radioButton.checked).toBe(true);
  });
});
```

## Component Integration

### Template Integration

Add component to template's components.yml:

```yaml
# templates/educational/components.yml
components:
  - name: quiz-engine
    version: "1.0.0"
    config:
      theme: "modern"
      progress_tracking: true
      passing_score: 80

  - name: analytics
    version: "2.1.0"
    config:
      provider: "google"
      track_quiz_events: true
```

### Content Usage

Use component in content files:

```markdown
---
title: "JavaScript Fundamentals Quiz"
description: "Test your JavaScript knowledge"
type: "quiz"
---

# JavaScript Fundamentals

Before we begin, let's test your current JavaScript knowledge:

{{< quiz id="js-fundamentals" file="javascript-basics" >}}

This quiz covers basic JavaScript concepts including:
- Variables and data types
- Functions and scope
- Objects and arrays
- Control flow

{{< quiz id="advanced-js" file="javascript-advanced" >}}
```

### Data Structure

Define quiz data in Hugo data files:

```yaml
# data/quizzes/javascript-basics.yml
title: "JavaScript Basics Quiz"
description: "Test your understanding of fundamental JavaScript concepts"
passing_score: 70
time_limit: 600

questions:
  - question: "Which of the following is NOT a primitive data type in JavaScript?"
    type: "single-choice"
    options:
      - "string"
      - "number"
      - "array"
      - "boolean"
    correct: 2
    explanation: "Arrays are objects in JavaScript, not primitive types. The primitive types are string, number, boolean, undefined, null, symbol, and bigint."

  - question: "Select all valid ways to declare a variable in JavaScript:"
    type: "multiple-choice"
    options:
      - "var myVar = 5;"
      - "let myVar = 5;"
      - "const myVar = 5;"
      - "variable myVar = 5;"
    correct: [0, 1, 2]
    explanation: "JavaScript supports var, let, and const for variable declaration. 'variable' is not a valid keyword."

  - question: "What will console.log(typeof null) output?"
    type: "input-field"
    correct: "object"
    explanation: "This is a famous JavaScript quirk - typeof null returns 'object' due to a historical bug that was never fixed for compatibility reasons."
```

## Component Distribution

### Package.json Configuration

Prepare component for distribution:

```json
{
  "name": "@info-tech-io/hugo-quiz-engine",
  "version": "1.0.0",
  "description": "Interactive quiz component for Hugo Template Factory",
  "main": "component.yml",
  "files": [
    "layouts/",
    "static/",
    "data/",
    "config.yml",
    "component.yml",
    "README.md"
  ],
  "scripts": {
    "build": "npm run build:css && npm run build:js",
    "build:css": "sass static/css/quiz-engine.scss static/css/quiz-engine.css",
    "build:js": "tsc static/js/quiz-engine.ts --outDir static/js/",
    "test": "jest",
    "lint": "eslint static/js/ --ext .ts",
    "validate": "node scripts/validate-component.js"
  },
  "keywords": [
    "hugo",
    "component",
    "quiz",
    "education",
    "interactive"
  ],
  "author": "info-tech-io",
  "license": "Apache-2.0",
  "repository": {
    "type": "git",
    "url": "https://github.com/info-tech-io/hugo-templates.git",
    "directory": "components/quiz-engine"
  },
  "dependencies": {},
  "devDependencies": {
    "@types/jest": "^29.0.0",
    "jest": "^29.0.0",
    "typescript": "^5.0.0",
    "sass": "^1.60.0",
    "eslint": "^8.0.0"
  },
  "peerDependencies": {
    "hugo": ">=0.120.0"
  }
}
```

### Component Registry

Register component in the factory's component registry:

```yaml
# registry/components.yml
components:
  quiz-engine:
    name: "Quiz Engine"
    description: "Interactive educational quizzes with progress tracking"
    version: "1.0.0"
    author: "info-tech-io"
    category: "education"
    tags: ["interactive", "assessment", "learning"]

    compatibility:
      hugo_version: ">=0.120.0"
      templates: ["default", "academic", "educational"]
      themes: ["compose", "minimal"]

    dependencies:
      optional:
        - name: "analytics"
          version: ">=2.0.0"
          reason: "Event tracking and user analytics"

    installation:
      method: "built-in"
      size: "~50KB (minified)"

    documentation:
      readme: "components/quiz-engine/README.md"
      examples: "components/quiz-engine/docs/examples.md"
      api: "components/quiz-engine/docs/api.md"

    support:
      issues: "https://github.com/info-tech-io/hugo-templates/issues"
      discussions: "https://github.com/info-tech-io/hugo-templates/discussions"

    metrics:
      downloads: 0
      stars: 0
      last_updated: "2025-01-01T00:00:00Z"
```

## Best Practices

### 1. Design Principles

- **Modularity**: Components should be self-contained and reusable
- **Accessibility**: Follow WCAG guidelines for inclusive design
- **Performance**: Optimize for fast loading and smooth interactions
- **Compatibility**: Support multiple Hugo versions and templates

### 2. Code Quality

- **TypeScript**: Use TypeScript for better type safety and developer experience
- **Testing**: Comprehensive unit and integration tests
- **Documentation**: Clear API documentation and usage examples
- **Linting**: Consistent code style with ESLint and Prettier

### 3. User Experience

- **Progressive Enhancement**: Work without JavaScript for basic functionality
- **Responsive Design**: Mobile-first responsive layout
- **Error Handling**: Graceful error handling and user feedback
- **Internationalization**: Support for multiple languages

### 4. Security Considerations

- **Input Validation**: Sanitize all user inputs
- **XSS Prevention**: Escape HTML output properly
- **Data Privacy**: Respect user privacy in analytics and tracking
- **Content Security Policy**: Compatible with strict CSP

## Troubleshooting

### Common Issues

#### Component Not Loading
- Verify component.yml syntax
- Check Hugo version compatibility
- Ensure proper template integration

#### JavaScript Errors
- Check browser console for errors
- Verify script loading order
- Test with different browsers

#### Styling Issues
- Check CSS specificity conflicts
- Verify responsive breakpoints
- Test with different themes

### Debug Mode

Enable component debugging:

```javascript
// Add to component configuration
quiz_engine:
  debug: true
  verbose_logging: true
```

## Next Steps

- **Advanced Components**: [Advanced Component Development](./advanced-components.md)
- **Component Testing**: [Testing Strategies](./testing.md)
- **Performance Optimization**: [Performance Guide](../user-guides/performance.md)
- **Accessibility**: [Accessibility Guidelines](./accessibility.md)

## Related Documentation

- [Build System Guide](../user-guides/build-system.md)
- [Template Development](./templates.md)
- [API Reference](../api-reference/components.md)
- [Troubleshooting Guide](../troubleshooting/common-issues.md)