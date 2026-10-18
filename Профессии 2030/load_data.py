import pandas as pd
from sqlalchemy import create_engine

# Читаем CSV
df = pd.read_csv(r'C:\Users\Public\Documents\AI_Impact_on_Jobs_2030.csv', encoding='utf-8')
print(f"✅ Загружено {len(df)} строк")

# Подключаемся к SQL Server через SQLAlchemy
conn_str = (
    'mssql+pyodbc://@localhost/AI_Jobs_Analytics?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
)
engine = create_engine(conn_str)

# Загружаем данные
df.to_sql('ai_jobs', engine, if_exists='replace', index=False)
print("✅ Данные загружены в таблицу ai_jobs!")

# Проверяем
with engine.connect() as conn:
    result = conn.execute("SELECT COUNT(*) FROM ai_jobs")
    count = result.fetchone()[0]
    print(f"✅ В таблице {count} записей")