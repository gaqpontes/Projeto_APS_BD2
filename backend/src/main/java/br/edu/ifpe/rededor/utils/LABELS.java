package br.edu.ifpe.rededor.utils;

import java.util.Map;

public class LABELS {
   private static final Map<String, String> LABELS = Map.of(
    "PESSOA_CONTROLLER_CPF_INVALIDO", "CPF não pode ser nulo ou branco",
    "cpf", "CPF",
    "dataNascimento", "Data de nascimento",
    "endereco", "Endereço"
    );

    public static String getLabel(String key){
        return LABELS.get(key);
    }
    
    public static String getLabel(String key, String defaultValue){
        return LABELS.containsKey(key) ? LABELS.get(key) : defaultValue;
    }
    
}
