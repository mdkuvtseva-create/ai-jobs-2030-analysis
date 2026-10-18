import pandas as pd
from sqlalchemy import create_engine, text

# 1. Читаем CSV
file_path = r'C:\Users\Public\Documents\AI_Impact_on_Jobs_2030.csv'
print(f"📂 Читаю файл: {file_path}")

df = pd.read_csv(file_path, encoding='utf-8')
print(f"✅ Загружено {len(df)} строк из CSV")

# 2. Подключаемся к SQL Server
conn_str = (
    'mssql+pyodbc://@localhost/AI_Jobs_Analytics?'
    'driver=ODBC+Driver+17+for+SQL+Server&'
    'trusted_connection=yes'
)
engine = create_engine(conn_str)

# 3. Проверяем подключение
with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
    print("✅ Подключение к SQL Server успешно!")

# 4. Удаляем старую таблицу, если есть
with engine.connect() as conn:
    conn.execute(text("DROP TABLE IF EXISTS ai_jobs"))
    conn.commit()
    print("✅ Старая таблица удалена (если была)")

# 5. Загружаем данные
df.to_sql('ai_jobs', engine, if_exists='replace', index=False)
print("✅ Данные загружены в таблицу ai_jobs!")

# 6. Проверяем, сколько записей
with engine.connect() as conn:
    result = conn.execute(text("SELECT COUNT(*) FROM ai_jobs"))
    count = result.fetchone()[0]
    print(f"✅ В таблице {count} записей")

print("🎉 ГОТОВО!")