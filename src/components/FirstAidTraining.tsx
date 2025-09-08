import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { 
  Heart, 
  Play, 
  CheckCircle, 
  Clock, 
  AlertTriangle,
  Shield,
  Flame,
  User
} from 'lucide-react';

interface TrainingModule {
  id: string;
  title: string;
  description: string;
  duration: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  icon: React.ElementType;
  completed: boolean;
  progress: number;
  steps: string[];
}

const FirstAidTraining: React.FC = () => {
  const [selectedModule, setSelectedModule] = useState<TrainingModule | null>(null);
  const [currentStep, setCurrentStep] = useState(0);

  const trainingModules: TrainingModule[] = [
    {
      id: 'cpr',
      title: 'CPR (Cardiopulmonary Resuscitation)',
      description: 'Learn life-saving chest compressions and rescue breathing',
      duration: '15 min',
      difficulty: 'Intermediate',
      icon: Heart,
      completed: true,
      progress: 100,
      steps: [
        'Check for responsiveness and call for help',
        'Position hands on the center of the chest',
        'Push hard and fast at least 2 inches deep',
        'Give 30 chest compressions at 100-120 bpm',
        'Tilt head back, lift chin, give 2 rescue breaths',
        'Continue cycles of 30 compressions and 2 breaths'
      ]
    },
    {
      id: 'choking',
      title: 'Choking Response',
      description: 'How to help someone who is choking',
      duration: '10 min',
      difficulty: 'Beginner',
      icon: AlertTriangle,
      completed: false,
      progress: 60,
      steps: [
        'Ask "Are you choking?" Look for the universal choking sign',
        'If they can cough or speak, encourage coughing',
        'If they cannot breathe, give 5 back blows',
        'Give 5 abdominal thrusts (Heimlich maneuver)',
        'Continue alternating back blows and abdominal thrusts',
        'Call emergency services if object is not dislodged'
      ]
    },
    {
      id: 'bleeding',
      title: 'Severe Bleeding Control',
      description: 'Stop life-threatening bleeding quickly',
      duration: '12 min',
      difficulty: 'Intermediate',
      icon: AlertTriangle,
      completed: false,
      progress: 0,
      steps: [
        'Ensure your safety and wear gloves if available',
        'Apply direct pressure with clean cloth or gauze',
        'Do not remove cloth if it becomes soaked',
        'Add more layers and continue pressure',
        'Elevate the wound if possible',
        'Apply pressure to pressure points if needed'
      ]
    },
    {
      id: 'burns',
      title: 'Burn Treatment',
      description: 'Proper care for different types of burns',
      duration: '8 min',
      difficulty: 'Beginner',
      icon: Flame,
      completed: false,
      progress: 0,
      steps: [
        'Remove from heat source safely',
        'Cool burn with running water for 10-20 minutes',
        'Never use ice on burns',
        'Cover with clean, non-stick dressing',
        'Do not break blisters',
        'Seek medical attention for severe burns'
      ]
    },
    {
      id: 'recovery-position',
      title: 'Recovery Position',
      description: 'Safe positioning for unconscious but breathing person',
      duration: '6 min',
      difficulty: 'Beginner',
      icon: User,
      completed: false,
      progress: 0,
      steps: [
        'Check for response and breathing',
        'Kneel beside the person',
        'Place far arm at right angle to body',
        'Bring near arm across chest',
        'Roll person toward you using leg and shoulder',
        'Adjust head to keep airway open'
      ]
    },
    {
      id: 'self-defense',
      title: 'Basic Self-Defense',
      description: 'Essential techniques for personal safety',
      duration: '20 min',
      difficulty: 'Advanced',
      icon: Shield,
      completed: false,
      progress: 0,
      steps: [
        'Maintain awareness of surroundings',
        'Use loud voice to deter attackers',
        'Target vulnerable areas: eyes, nose, groin',
        'Strike with palm heel, not fist',
        'Create distance and escape',
        'Report incidents to authorities'
      ]
    }
  ];

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Beginner': return 'bg-medical text-medical-foreground';
      case 'Intermediate': return 'bg-warning text-warning-foreground';
      case 'Advanced': return 'bg-emergency text-emergency-foreground';
      default: return 'bg-secondary text-secondary-foreground';
    }
  };

  const handleStartModule = (module: TrainingModule) => {
    setSelectedModule(module);
    setCurrentStep(0);
  };

  const handleNextStep = () => {
    if (selectedModule && currentStep < selectedModule.steps.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePreviousStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleCompleteModule = () => {
    if (selectedModule) {
      // In a real app, this would update the backend
      console.log(`Completed module: ${selectedModule.title}`);
      setSelectedModule(null);
      setCurrentStep(0);
    }
  };

  if (selectedModule) {
    return (
      <div className="max-w-4xl mx-auto space-y-4">
        <div className="flex items-center justify-between">
          <Button 
            variant="ghost" 
            onClick={() => setSelectedModule(null)}
            className="text-muted-foreground hover:text-foreground"
          >
            ← Back to Modules
          </Button>
          <Badge className={getDifficultyColor(selectedModule.difficulty)}>
            {selectedModule.difficulty}
          </Badge>
        </div>

        <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-2xl bg-gradient-medical text-medical-foreground">
                <selectedModule.icon className="w-6 h-6" />
              </div>
              <div>
                <CardTitle>{selectedModule.title}</CardTitle>
                <CardDescription>{selectedModule.description}</CardDescription>
              </div>
            </div>
            <div className="mt-4">
              <div className="flex justify-between text-sm text-muted-foreground mb-2">
                <span>Step {currentStep + 1} of {selectedModule.steps.length}</span>
                <span>{Math.round(((currentStep + 1) / selectedModule.steps.length) * 100)}% Complete</span>
              </div>
              <Progress value={((currentStep + 1) / selectedModule.steps.length) * 100} className="h-2" />
            </div>
          </CardHeader>
        </Card>

        <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
          <CardContent className="p-8">
            <div className="text-center space-y-6">
              <div className="bg-gradient-medical/10 p-6 rounded-2xl">
                <h3 className="text-xl font-semibold mb-4">
                  Step {currentStep + 1}: {selectedModule.steps[currentStep]}
                </h3>
                <div className="text-muted-foreground">
                  Follow this step carefully and ensure you understand before proceeding.
                </div>
              </div>

              <div className="flex justify-center gap-4">
                <Button 
                  variant="outline" 
                  onClick={handlePreviousStep}
                  disabled={currentStep === 0}
                >
                  Previous Step
                </Button>
                {currentStep === selectedModule.steps.length - 1 ? (
                  <Button 
                    onClick={handleCompleteModule}
                    className="bg-gradient-medical text-medical-foreground hover:opacity-90"
                  >
                    <CheckCircle className="w-4 h-4 mr-2" />
                    Complete Module
                  </Button>
                ) : (
                  <Button 
                    onClick={handleNextStep}
                    className="bg-gradient-safety text-safety-foreground hover:opacity-90"
                  >
                    Next Step
                  </Button>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <Card className="border-0 shadow-sm bg-card/50 backdrop-blur-sm">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-medical" />
            First Aid Training Center
          </CardTitle>
          <CardDescription>
            Learn essential life-saving skills through interactive training modules
          </CardDescription>
        </CardHeader>
      </Card>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {trainingModules.map((module) => (
          <Card 
            key={module.id} 
            className="border-0 shadow-sm bg-card/50 backdrop-blur-sm hover:shadow-md transition-all cursor-pointer group"
            onClick={() => handleStartModule(module)}
          >
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className={`p-3 rounded-2xl ${module.completed ? 'bg-gradient-medical' : 'bg-muted'} ${module.completed ? 'text-medical-foreground' : 'text-muted-foreground'}`}>
                    {module.completed ? <CheckCircle className="w-5 h-5" /> : <module.icon className="w-5 h-5" />}
                  </div>
                  <div className="flex-1">
                    <CardTitle className="text-sm">{module.title}</CardTitle>
                    <div className="flex items-center gap-2 mt-1">
                      <Badge variant="secondary" className="text-xs">
                        <Clock className="w-3 h-3 mr-1" />
                        {module.duration}
                      </Badge>
                      <Badge className={`text-xs ${getDifficultyColor(module.difficulty)}`}>
                        {module.difficulty}
                      </Badge>
                    </div>
                  </div>
                </div>
              </div>
              <CardDescription className="mt-2">
                {module.description}
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="space-y-3">
                <div>
                  <div className="flex justify-between text-sm text-muted-foreground mb-1">
                    <span>Progress</span>
                    <span>{module.progress}%</span>
                  </div>
                  <Progress value={module.progress} className="h-2" />
                </div>
                <Button 
                  className="w-full group-hover:shadow-md transition-all" 
                  variant={module.completed ? "secondary" : "default"}
                >
                  {module.completed ? (
                    <>
                      <CheckCircle className="w-4 h-4 mr-2" />
                      Review
                    </>
                  ) : (
                    <>
                      <Play className="w-4 h-4 mr-2" />
                      {module.progress > 0 ? 'Continue' : 'Start Training'}
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default FirstAidTraining;