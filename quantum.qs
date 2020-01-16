namespace Microsoft.Samples
{
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Arithmetic;
  open Microsoft.Quantum.Convert;
  open Microsoft.Quantum.Arrays;
  open Microsoft.Quantum.Canon;
  open Microsoft.Quantum.Math;



  /// This peration copies a classical number into a Qubit using LittleEndian notation.
  /// The binary value of the classical number and the Qubit array need to have
  /// the same length l.
  /// The initial state of all Qubits is supposed to be |0>.
  operation QuantumCopy(register: Qubit[], number : Int, length: Int) : Unit
  {
    body {
      mutable exponent = number;
      for(i in 0 .. (length-1)){
        if(exponent%2!=0){
          X(register[i]);
        }
        set exponent = exponent/2;
      }
    }
  }
  operation MeasureRegister(register : Qubit[], length : Int) : (Int)
  {
    body{
      mutable result = 0;
      for(i in 0 .. (length - 1)){
        let m = (M(register[length-1-i]) == Zero ? 0 | 1);
        set result = result + Floor(PowD(2.0,IntAsDouble(i))) * m;
      }
      return result;
    }
  }
  operation ModularExponentiation
    ( module : Int,
      base: Int,
      exponent : Qubit[],
      length : Int,
      target : Qubit[]) : Unit{
    body{
      ///set the target to 1 in Little Endian notation
      X(target[0]);

      /// using the MultiplyByModularInteger operation to implements the modular Exponentiation.
      for( i in 0 .. (length-1)){
        let multiplier = Floor(PowD(IntAsDouble(base), PowD(2.0,IntAsDouble(i))))%module;
        (Controlled MultiplyByModularInteger) ([exponent[i]], (multiplier, module, LittleEndian(target)));
      }
    }
  }

  operation ModularMultiplication(a : Qubit[], b : Qubit[], result : Qubit[], length : Int, module :Int) : Unit
  {
    body{
      for (i in 0 .. length - 1){
        let k = Floor(PowD(2.0,IntAsDouble(i)));
        for ( j in 0 .. k - 1){
          (Controlled MultiplyAndAddByModularInteger) ([a[i]], (1, module, LittleEndian(b), LittleEndian(result)));
        }

      }
    }
  }
  operation multiHGate(target : Qubit[], length : Int) : Unit
  {
    body{
      for (i in 0 .. (length - 1)){
        H(target[i]);
      }
    }
  }


  /// prime = number of elements in G
  /// a, b = random numbers
  /// l = length of the registers
  /// x = target value
  /// g = generator of G

  operation Shor(prime : Int, a : Int, b : Int, l : Int, x : Int, g : Int) : (Int, Int)
  {
    using (target = Qubit[l*5]){
      let temp = Partitioned([l,l,l,l,l], target);
      /// The classical number a is copied in the Qubit register quantum-1 and put in superposition
      QuantumCopy(temp[0], a, l);
      let quantum_a = temp[0];
      multiHGate(quantum_a, l);
      let quantum_ga = temp[1];
      Message("a");
      /// calculate g^a in quantum_2
      ModularExponentiation(prime, g, quantum_a, l, quantum_ga);
      Message("g^a");
      /// The classical number b is copied in the Qubit register quantum-3 and put in superposition
      QuantumCopy(temp[2], b, l);
      let quantum_b = temp[2];
      multiHGate(quantum_b, l);
      Message("b");
      let quantum_xb = temp[3];
      /// calculate x^b in quantum_4
      ModularExponentiation(prime, g, quantum_b, l, quantum_xb);

      Message("x^b");
      ///calculate g^a*x-b in quantum_5
      let quantum_gaxb = temp[4];
      ModularMultiplication (quantum_ga, quantum_xb, quantum_gaxb, l, prime);

      Message("g^a*x^b");
      /// QTF over the basic 2 register
      ApproximateQFT(1,LittleEndianAsBigEndian(LittleEndian(quantum_a)));
      ApproximateQFT(1,LittleEndianAsBigEndian(LittleEndian(quantum_b)));

      Message("QTF");
      /// Measure the basic 2 register
      let c = MeasureRegister(quantum_a, l);
      let d = MeasureRegister(quantum_b, l);
      return (c,d);
    }
  }
}


/// /// The classical number a is copied in the Qubit register quantum-1 and put in superposition
/// QuantumCopy(temp[0], a, l);
/// let quantum_1 = temp[0]
/// multiHGate(quantum_1, l);
/// let quantum_2 = temp[1];
/// /// calculate g^a in quantum_2
/// ModularExponentiation(prime, g, quantum_1, l, quantum_2);
///
/// /// The classical number b is copied in the Qubit register quantum-3 and put in superposition
/// QuantumCopy(temp[2], b, l);
/// let quantum_3 = temp[2]
/// multiHGate(quantum_3, l);
/// let quantum_4 = temp[3];
/// /// calculate x^b in quantum_4
/// ModularExponentiation(prime, g, quantum_3, l, quantum_4);
///
/// ///calculate g^a*x-b in quantum_5
/// DivideI (quantum_2, quantum_4, quantum_5);
/// quantum_5 = temp[3];
///
/// /// QTF over the first 2 register
/// ApplyQuantumFourierTransform (quantum_1);
/// ApplyQuantumFourierTransform (quantum_2);
///
/// /// Measure the first 2 register
/// let c = Measure(quantum_1);
/// let d = Measure(quantum_2)
///
