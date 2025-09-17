@echo off
cd "C:\Users\YourUser\Documents\RATZAM-8"
git pull origin main
git add .
git commit -m "Auto-commit %date% %time%" 
git push origin main
echo RATZAM-8 project pushed successfully!
pause

