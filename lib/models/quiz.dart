class Question {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int level;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.level,
  });
}

class QuizData {
  static List<Question> getAllQuestions() {
    return [
      // Level 1
      Question(
        question: 'What is the capital of France?',
        options: ['London', 'Paris', 'Berlin', 'Madrid'],
        correctAnswerIndex: 1,
        level: 1,
      ),
      Question(
        question: 'Which planet is known as the Red Planet?',
        options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
        correctAnswerIndex: 1,
        level: 1,
      ),
      Question(
        question: 'What is 2 + 2?',
        options: ['3', '4', '5', '6'],
        correctAnswerIndex: 1,
        level: 1,
      ),
      
      // Level 2
      Question(
        question: 'Who painted the Mona Lisa?',
        options: ['Van Gogh', 'Picasso', 'Da Vinci', 'Monet'],
        correctAnswerIndex: 2,
        level: 2,
      ),
      Question(
        question: 'What is the largest ocean on Earth?',
        options: ['Atlantic', 'Indian', 'Arctic', 'Pacific'],
        correctAnswerIndex: 3,
        level: 2,
      ),
      Question(
        question: 'How many continents are there?',
        options: ['5', '6', '7', '8'],
        correctAnswerIndex: 2,
        level: 2,
      ),
      
      // Level 3
      Question(
        question: 'What is the speed of light?',
        options: ['299,792 km/s', '150,000 km/s', '500,000 km/s', '1,000,000 km/s'],
        correctAnswerIndex: 0,
        level: 3,
      ),
      Question(
        question: 'Who wrote "Romeo and Juliet"?',
        options: ['Dickens', 'Shakespeare', 'Hemingway', 'Austen'],
        correctAnswerIndex: 1,
        level: 3,
      ),
      Question(
        question: 'What is the chemical symbol for gold?',
        options: ['Go', 'Gd', 'Au', 'Ag'],
        correctAnswerIndex: 2,
        level: 3,
      ),
      
      // Level 4
      Question(
        question: 'In which year did World War II end?',
        options: ['1943', '1944', '1945', '1946'],
        correctAnswerIndex: 2,
        level: 4,
      ),
      Question(
        question: 'What is the smallest prime number?',
        options: ['0', '1', '2', '3'],
        correctAnswerIndex: 2,
        level: 4,
      ),
      Question(
        question: 'Which element has the atomic number 1?',
        options: ['Helium', 'Hydrogen', 'Oxygen', 'Carbon'],
        correctAnswerIndex: 1,
        level: 4,
      ),
      
      // Level 5
      Question(
        question: 'What is the longest river in the world?',
        options: ['Amazon', 'Nile', 'Yangtze', 'Mississippi'],
        correctAnswerIndex: 1,
        level: 5,
      ),
      Question(
        question: 'Who developed the theory of relativity?',
        options: ['Newton', 'Einstein', 'Hawking', 'Galileo'],
        correctAnswerIndex: 1,
        level: 5,
      ),
      Question(
        question: 'What is the capital of Australia?',
        options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
        correctAnswerIndex: 2,
        level: 5,
      ),
    ];
  }

  static List<Question> getQuestionsForLevel(int level) {
    return getAllQuestions().where((q) => q.level == level).toList();
  }

  static int getTotalLevels() {
    return getAllQuestions().map((q) => q.level).reduce((a, b) => a > b ? a : b);
  }
}
