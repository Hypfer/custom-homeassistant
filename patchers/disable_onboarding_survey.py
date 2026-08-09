import os, sys

frontend_dir = sys.argv[1]
target = os.path.join(frontend_dir, "src", "util", "onboarding-survey.ts")

stub = """\
// Disable survey
export const shouldShowOnboardingSurvey = () => false;
export const recordOnboardingSurvey = async () => {};
export const getOnboardingSurveyUrl = () => "";
export const checkOnboardingSurveyToast = () => {};
"""

content = open(target, "r", encoding="utf-8").read()

if "checkOnboardingSurveyToast" in content:
    open(target, "w", encoding="utf-8").write(stub)
    print("  Onboarding survey disabled")
else:
    print("  Could not disable onboarding survey")
