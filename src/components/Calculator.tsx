import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface CalculatorProps {
  onUnlock: () => void;
}

const Calculator: React.FC<CalculatorProps> = ({ onUnlock }) => {
  const [display, setDisplay] = useState('0');
  const [previousValue, setPreviousValue] = useState<number | null>(null);
  const [operation, setOperation] = useState<string | null>(null);
  const [waitingForOperand, setWaitingForOperand] = useState(false);
  const [secretSequence, setSecretSequence] = useState<string[]>([]);
  
  const SECRET_CODE = ['=', '=', '=', '×', '÷'];

  const performCalculation = {
    '÷': (firstOperand: number, secondOperand: number) => firstOperand / secondOperand,
    '×': (firstOperand: number, secondOperand: number) => firstOperand * secondOperand,
    '+': (firstOperand: number, secondOperand: number) => firstOperand + secondOperand,
    '-': (firstOperand: number, secondOperand: number) => firstOperand - secondOperand,
    '=': (firstOperand: number, secondOperand: number) => secondOperand
  };

  const calculate = (firstOperand: number, secondOperand: number, operation: string) => {
    return performCalculation[operation as keyof typeof performCalculation](firstOperand, secondOperand);
  };

  const inputNumber = (num: string) => {
    if (waitingForOperand) {
      setDisplay(num);
      setWaitingForOperand(false);
    } else {
      setDisplay(display === '0' ? num : display + num);
    }
  };

  const inputOperation = (nextOperation: string) => {
    const inputValue = parseFloat(display);
    
    // Check secret sequence
    const newSequence = [...secretSequence, nextOperation].slice(-5);
    setSecretSequence(newSequence);
    
    if (JSON.stringify(newSequence) === JSON.stringify(SECRET_CODE)) {
      onUnlock();
      return;
    }

    if (previousValue === null) {
      setPreviousValue(inputValue);
    } else if (operation) {
      const currentValue = previousValue || 0;
      const newValue = calculate(currentValue, inputValue, operation);

      setDisplay(String(newValue));
      setPreviousValue(newValue);
    }

    setWaitingForOperand(true);
    setOperation(nextOperation);
  };

  const inputEqual = () => {
    inputOperation('=');
  };

  const clear = () => {
    setDisplay('0');
    setPreviousValue(null);
    setOperation(null);
    setWaitingForOperand(false);
    setSecretSequence([]);
  };

  const inputDecimal = () => {
    if (waitingForOperand) {
      setDisplay('0.');
      setWaitingForOperand(false);
    } else if (display.indexOf('.') === -1) {
      setDisplay(display + '.');
    }
  };

  const buttons = [
    { label: 'C', onClick: clear, className: 'col-span-2 bg-calculator-operator text-calculator-text' },
    { label: '÷', onClick: () => inputOperation('÷'), className: 'bg-calculator-operator text-calculator-text' },
    { label: '×', onClick: () => inputOperation('×'), className: 'bg-calculator-operator text-calculator-text' },
    
    { label: '7', onClick: () => inputNumber('7'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '8', onClick: () => inputNumber('8'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '9', onClick: () => inputNumber('9'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '-', onClick: () => inputOperation('-'), className: 'bg-calculator-operator text-calculator-text' },
    
    { label: '4', onClick: () => inputNumber('4'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '5', onClick: () => inputNumber('5'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '6', onClick: () => inputNumber('6'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '+', onClick: () => inputOperation('+'), className: 'bg-calculator-operator text-calculator-text' },
    
    { label: '1', onClick: () => inputNumber('1'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '2', onClick: () => inputNumber('2'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '3', onClick: () => inputNumber('3'), className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '=', onClick: inputEqual, className: 'row-span-2 bg-calculator-operator text-calculator-text' },
    
    { label: '0', onClick: () => inputNumber('0'), className: 'col-span-2 bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
    { label: '.', onClick: inputDecimal, className: 'bg-calculator-button text-calculator-number hover:bg-calculator-button-hover' },
  ];

  return (
    <div className="min-h-screen bg-gradient-calculator flex items-center justify-center p-4">
      <div className="bg-calculator-bg rounded-3xl p-8 shadow-2xl max-w-sm w-full">
        <div className="mb-6">
          <div className="bg-calculator-display rounded-2xl p-6 mb-4">
            <div className="text-right text-calculator-text text-3xl font-light overflow-hidden">
              {display}
            </div>
          </div>
          
          <div className="text-calculator-text/50 text-xs text-center">
            Calculator
          </div>
        </div>

        <div className="grid grid-cols-4 gap-3">
          {buttons.map((button, index) => (
            <Button
              key={index}
              onClick={button.onClick}
              className={cn(
                'h-16 rounded-2xl border-0 text-xl font-medium transition-all duration-200 active:scale-95',
                button.className
              )}
            >
              {button.label}
            </Button>
          ))}
        </div>
        
        <div className="mt-4 text-center text-calculator-text/30 text-xs">
          Hint: Press = = = × ÷
        </div>
      </div>
    </div>
  );
};

export default Calculator;