# Clean chicago_jobcenter
job_cfg = 'txData/Qbox_C6CA87.base/resources/[customs]/chicago_jobcenter/config.lua'
with open(job_cfg, 'r', encoding='utf-8') as f:
    text = f.read()

replacements = {
    "Freelancer (استقالة / عاطل)": "Freelancer (Unemployed)",
    "سائق تاكسي (Taxi Driver)": "Taxi Driver",
    "شاحنات البضائع (Trucker)": "Trucker",
    "عامل نظافة (Garbage Collector)": "Garbage Collector",
    "سائق حافلة (Bus Driver)": "Bus Driver",
    "شاحنة سحب (Tow Truck)": "Tow Truck",
    "صحفي / إعلامي (News Reporter)": "News Reporter",
}
for k, v in replacements.items():
    text = text.replace(k, v)

with open(job_cfg, 'w', encoding='utf-8') as f:
    f.write(text)

job_cl = 'txData/Qbox_C6CA87.base/resources/[customs]/chicago_jobcenter/client/main.lua'
with open(job_cl, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('مركز التوظيف | Job Center', 'Job Center')
text = text.replace('مركز التوظيف | Employment Office', 'Job Center')

with open(job_cl, 'w', encoding='utf-8') as f:
    f.write(text)

print("Cleaned chicago_jobcenter of all Arabic")

