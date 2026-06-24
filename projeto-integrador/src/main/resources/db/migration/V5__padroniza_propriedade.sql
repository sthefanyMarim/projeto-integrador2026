-- Telefone: normaliza valores fora do padrao (55) 9999-9999 / (55) 99999-9999 para NULL antes de travar o formato
UPDATE propriedades
SET telefone = NULL
WHERE telefone IS NOT NULL
  AND telefone !~ '^\(\d{2}\) \d{4,5}-\d{4}$';

ALTER TABLE propriedades
    ADD CONSTRAINT chk_propriedades_telefone
    CHECK (telefone IS NULL OR telefone ~ '^\(\d{2}\) \d{4,5}-\d{4}$');

-- Tipo de producao: passa de texto livre para lista fechada
CREATE TYPE tipo_producao AS ENUM (
    'AGRICULTURA_FAMILIAR',
    'AGRICULTURA_CONVENCIONAL',
    'AGROECOLOGICA_ORGANICA',
    'PECUARIA',
    'FRUTICULTURA',
    'HORTICULTURA',
    'AVICULTURA',
    'PISCICULTURA',
    'SILVICULTURA',
    'MISTA',
    'OUTROS'
);

ALTER TABLE propriedades
    ALTER COLUMN tipo_producao TYPE tipo_producao
    USING (
        CASE
            WHEN tipo_producao IS NULL THEN NULL
            WHEN upper(tipo_producao) = ANY (enum_range(NULL::tipo_producao)::text[])
                THEN upper(tipo_producao)::tipo_producao
            ELSE 'OUTROS'::tipo_producao
        END
    );
