import 'package:flutter/material.dart';

class TrainingModule {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final IconData icon;
  bool completed;
  int progress;
  final List<String> steps;

  TrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.icon,
    this.completed = false,
    this.progress = 0,
    required this.steps,
  });
}

class FirstAidTrainingScreen extends StatefulWidget {
  const FirstAidTrainingScreen({super.key});

  @override
  State<FirstAidTrainingScreen> createState() => _FirstAidTrainingScreenState();
}

class _FirstAidTrainingScreenState extends State<FirstAidTrainingScreen> {
  TrainingModule? selectedModule;
  int currentStep = 0;

  final List<TrainingModule> trainingModules = [
    TrainingModule(
      id: 'cpr',
      title: 'CPR (Cardiopulmonary Resuscitation)',
      description: 'Learn life-saving chest compressions and rescue breathing',
      duration: '15 min',
      difficulty: 'Intermediate',
      icon: Icons.favorite,
      completed: true,
      progress: 100,
      steps: [
        'Check for responsiveness and call for help',
        'Position hands on the center of the chest',
        'Push hard and fast at least 2 inches deep',
        'Give 30 chest compressions at 100-120 bpm',
        'Tilt head back, lift chin, give 2 rescue breaths',
        'Continue cycles of 30 compressions and 2 breaths',
      ],
    ),
    TrainingModule(
      id: 'choking',
      title: 'Choking Response',
      description: 'How to help someone who is choking',
      duration: '10 min',
      difficulty: 'Beginner',
      icon: Icons.warning,
      completed: false,
      progress: 60,
      steps: [
        'Ask "Are you choking?" Look for the universal choking sign',
        'If they can cough or speak, encourage coughing',
        'If they cannot breathe, give 5 back blows',
        'Give 5 abdominal thrusts (Heimlich maneuver)',
        'Continue alternating back blows and abdominal thrusts',
        'Call emergency services if object is not dislodged',
      ],
    ),
    TrainingModule(
      id: 'bleeding',
      title: 'Severe Bleeding Control',
      description: 'Stop life-threatening bleeding quickly',
      duration: '12 min',
      difficulty: 'Intermediate',
      icon: Icons.bloodtype,
      completed: false,
      progress: 0,
      steps: [
        'Ensure your safety and wear gloves if available',
        'Apply direct pressure with clean cloth or gauze',
        'Do not remove cloth if it becomes soaked',
        'Add more layers and continue pressure',
        'Elevate the wound if possible',
        'Apply pressure to pressure points if needed',
      ],
    ),
    TrainingModule(
      id: 'burns',
      title: 'Burn Treatment',
      description: 'Proper care for different types of burns',
      duration: '8 min',
      difficulty: 'Beginner',
      icon: Icons.local_fire_department,
      completed: false,
      progress: 0,
      steps: [
        'Remove from heat source safely',
        'Cool burn with running water for 10-20 minutes',
        'Never use ice on burns',
        'Cover with clean, non-stick dressing',
        'Do not break blisters',
        'Seek medical attention for severe burns',
      ],
    ),
    TrainingModule(
      id: 'recovery-position',
      title: 'Recovery Position',
      description: 'Safe positioning for unconscious but breathing person',
      duration: '6 min',
      difficulty: 'Beginner',
      icon: Icons.person,
      completed: false,
      progress: 0,
      steps: [
        'Check for response and breathing',
        'Kneel beside the person',
        'Place far arm at right angle to body',
        'Bring near arm across chest',
        'Roll person toward you using leg and shoulder',
        'Adjust head to keep airway open',
      ],
    ),
    TrainingModule(
      id: 'self-defense',
      title: 'Basic Self-Defense',
      description: 'Essential techniques for personal safety',
      duration: '20 min',
      difficulty: 'Advanced',
      icon: Icons.shield,
      completed: false,
      progress: 0,
      steps: [
        'Maintain awareness of surroundings',
        'Use loud voice to deter attackers',
        'Target vulnerable areas: eyes, nose, groin',
        'Strike with palm heel, not fist',
        'Create distance and escape',
        'Report incidents to authorities',
      ],
    ),
  ];

  Color getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green.shade100;
      case 'Intermediate':
        return Colors.orange.shade100;
      case 'Advanced':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  void handleStartModule(TrainingModule module) {
    setState(() {
      selectedModule = module;
      currentStep = 0;
    });
  }

  void handleNextStep() {
    if (selectedModule != null &&
        currentStep < selectedModule!.steps.length - 1) {
      setState(() {
        currentStep++;
      });
    }
  }

  void handlePreviousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  void handleCompleteModule() {
    if (selectedModule != null) {
      setState(() {
        selectedModule!.completed = true;
        selectedModule = null;
        currentStep = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('First Aid Training Center')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: selectedModule == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn essential life-saving skills through interactive training modules',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: trainingModules.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final module = trainingModules[index];
                        return GestureDetector(
                          onTap: () => handleStartModule(module),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: getDifficultyColor(
                                          module.difficulty,
                                        ),
                                        child: Icon(
                                          module.icon,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          module.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    module.description,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        module.duration,
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      SizedBox(width: 16),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getDifficultyColor(
                                            module.difficulty,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          module.difficulty,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: module.progress / 100,
                                    backgroundColor: Colors.grey[300],
                                    color: module.completed
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '${module.progress}% Complete',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(selectedModule!.icon, size: 32),
                      SizedBox(width: 12),
                      Text(
                        selectedModule!.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: getDifficultyColor(selectedModule!.difficulty),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedModule!.difficulty,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: ((currentStep + 1) / selectedModule!.steps.length),
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Step ${currentStep + 1} of ${selectedModule!.steps.length}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Step ${currentStep + 1}:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            selectedModule!.steps[currentStep],
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: currentStep == 0
                                    ? null
                                    : handlePreviousStep,
                                child: Text('Previous Step'),
                              ),
                              currentStep == selectedModule!.steps.length - 1
                                  ? ElevatedButton(
                                      onPressed: handleCompleteModule,
                                      child: Text('Complete Module'),
                                    )
                                  : ElevatedButton(
                                      onPressed: handleNextStep,
                                      child: Text('Next Step'),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => selectedModule = null),
                    child: Text('← Back to Modules'),
                  ),
                ],
              ),
      ),
    );
  }
}
