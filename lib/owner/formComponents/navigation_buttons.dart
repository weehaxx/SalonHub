import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationButtons extends StatelessWidget {
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;

  const NavigationButtons({
    required this.currentStep,
    required this.onNext,
    required this.onPrevious,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          currentStep > 0
              ? ElevatedButton(
                  onPressed: onPrevious,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff355E3B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xff355E3B)),
                    ),
                  ),
                  child: Text(
                    'Previous',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ElevatedButton(
            onPressed: currentStep == 4 ? onSubmit : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff355E3B),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xff355E3B)),
              ),
            ),
            child: Text(
              currentStep == 4 ? 'Submit' : 'Next',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
