class QuizQuestion {
  final String questionId;
  final String category; // 'Logical Fallacy', 'Debate Technique', 'Topic'
  final String question;
  final List<String> options; // exactly 4 options
  final int correctIndex; // 0-3
  final String explanation;
  final String difficulty; // easy | medium | hard

  const QuizQuestion({
    required this.questionId,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
    this.difficulty = 'medium',
  });

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        'category': category,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'difficulty': difficulty,
      };

  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
        questionId: map['questionId'] as String? ?? '',
        category: map['category'] as String? ?? 'General',
        question: map['question'] as String? ?? '',
        options: List<String>.from(map['options'] as List? ?? const []),
        correctIndex: map['correctIndex'] as int? ?? 0,
        explanation: map['explanation'] as String? ?? '',
        difficulty: map['difficulty'] as String? ?? 'medium',
      );
}

/// Seed bank — covers logical fallacies, debate techniques, and topic content.
/// Stored in Firestore collection `quizQuestions` via the seed button.
const List<QuizQuestion> kSampleQuizQuestions = [
  // ---------------- Logical Fallacy ----------------
  QuizQuestion(
    questionId: 'q1',
    category: 'Logical Fallacy',
    question:
        'A debater says: "We shouldn\'t listen to her argument about climate policy because she failed her economics class." Which fallacy is this?',
    options: ['Straw man', 'Ad hominem', 'False dilemma', 'Slippery slope'],
    correctIndex: 1,
    explanation:
        'Ad hominem attacks the person instead of their argument. Her grades say nothing about the validity of her climate claim.',
    difficulty: 'easy',
  ),
  QuizQuestion(
    questionId: 'q2',
    category: 'Logical Fallacy',
    question:
        '"Either we ban all cars, or the planet is doomed." What logical fallacy does this statement commit?',
    options: [
      'False dilemma',
      'Appeal to authority',
      'Hasty generalization',
      'Circular reasoning'
    ],
    correctIndex: 0,
    explanation:
        'A false dilemma presents only two options when more exist. There are many policy options between "ban all cars" and "doom".',
    difficulty: 'easy',
  ),
  QuizQuestion(
    questionId: 'q3',
    category: 'Logical Fallacy',
    question:
        'Misrepresenting an opponent\'s argument to make it easier to attack is known as which fallacy?',
    options: ['Red herring', 'Straw man', 'Bandwagon', 'Tu quoque'],
    correctIndex: 1,
    explanation:
        'The straw man fallacy distorts the opponent\'s position into a weaker "straw" version that is easier to knock down.',
    difficulty: 'medium',
  ),
  QuizQuestion(
    questionId: 'q4',
    category: 'Logical Fallacy',
    question:
        '"Everyone is switching to this app, so it must be the best one." This reasoning is an example of:',
    options: [
      'Appeal to emotion',
      'Bandwagon (appeal to popularity)',
      'False cause',
      'Begging the question'
    ],
    correctIndex: 1,
    explanation:
        'The bandwagon fallacy assumes something is true or good simply because many people believe or do it.',
    difficulty: 'easy',
  ),
  QuizQuestion(
    questionId: 'q5',
    category: 'Logical Fallacy',
    question:
        '"If we allow students to redo one exam, soon they\'ll demand to redo every exam and grades will become meaningless." Which fallacy is this?',
    options: [
      'Slippery slope',
      'Ad hominem',
      'Appeal to authority',
      'Equivocation'
    ],
    correctIndex: 0,
    explanation:
        'The slippery slope fallacy claims one small step will inevitably lead to extreme consequences without evidence for that chain.',
    difficulty: 'medium',
  ),
  // ---------------- Debate Technique ----------------
  QuizQuestion(
    questionId: 'q6',
    category: 'Debate Technique',
    question:
        'In formal debate, what is the primary purpose of "rebuttal"?',
    options: [
      'To introduce your first argument',
      'To directly respond to and weaken the opponent\'s arguments',
      'To summarise the entire debate',
      'To thank the judges'
    ],
    correctIndex: 1,
    explanation:
        'A rebuttal directly engages the opposing side\'s points and explains why they are flawed or insufficient.',
    difficulty: 'easy',
  ),
  QuizQuestion(
    questionId: 'q7',
    category: 'Debate Technique',
    question:
        'The "signposting" technique in a debate speech refers to:',
    options: [
      'Pointing at your opponent',
      'Clearly telling the audience the structure of your argument',
      'Using physical gestures',
      'Quoting famous people'
    ],
    correctIndex: 1,
    explanation:
        'Signposting guides listeners through your speech ("First… Second… Finally…") so your argument is easy to follow.',
    difficulty: 'medium',
  ),
  QuizQuestion(
    questionId: 'q8',
    category: 'Debate Technique',
    question:
        'A strong argument typically follows which structure?',
    options: [
      'Claim → Evidence → Reasoning (warrant)',
      'Opinion → Insult → Conclusion',
      'Question → Question → Question',
      'Story → Joke → Story'
    ],
    correctIndex: 0,
    explanation:
        'A complete argument makes a claim, backs it with evidence, and explains the reasoning (warrant) linking the two.',
    difficulty: 'medium',
  ),
  QuizQuestion(
    questionId: 'q9',
    category: 'Debate Technique',
    question:
        'What does "burden of proof" mean in a debate?',
    options: [
      'The side proposing a claim must provide evidence for it',
      'The judge must prove who won',
      'The audience must vote',
      'Both sides must stay silent'
    ],
    correctIndex: 0,
    explanation:
        'Whoever asserts a claim carries the burden of proof — they must support it, rather than expecting others to disprove it.',
    difficulty: 'medium',
  ),
  QuizQuestion(
    questionId: 'q10',
    category: 'Debate Technique',
    question:
        'Steelmanning an opponent\'s argument means:',
    options: [
      'Ignoring it completely',
      'Addressing the strongest possible version of their argument',
      'Mocking it',
      'Repeating it word for word'
    ],
    correctIndex: 1,
    explanation:
        'Steelmanning is the opposite of a straw man — you engage the strongest form of the opposing argument, which makes your rebuttal more credible.',
    difficulty: 'hard',
  ),
  // ---------------- Topic Content ----------------
  QuizQuestion(
    questionId: 'q11',
    category: 'Topic',
    question:
        'Which UN Sustainable Development Goal focuses on "Quality Education"?',
    options: ['SDG 3', 'SDG 4', 'SDG 8', 'SDG 13'],
    correctIndex: 1,
    explanation:
        'SDG 4 aims to ensure inclusive and equitable quality education and promote lifelong learning opportunities for all.',
    difficulty: 'easy',
  ),
  QuizQuestion(
    questionId: 'q12',
    category: 'Topic',
    question:
        'In a debate about nuclear energy and climate change, which is the strongest PRO argument?',
    options: [
      'Nuclear plants look impressive',
      'Nuclear energy produces low carbon emissions at scale',
      'People like electricity',
      'It has been around a long time'
    ],
    correctIndex: 1,
    explanation:
        'Low-carbon, high-density baseload generation is the core evidence-based argument in favour of nuclear energy for climate goals.',
    difficulty: 'medium',
  ),
];
