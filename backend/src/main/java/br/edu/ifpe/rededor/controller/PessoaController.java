package br.edu.ifpe.rededor.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import br.edu.ifpe.rededor.dto.PessoaDTO;
import br.edu.ifpe.rededor.exception.CustomException;
import br.edu.ifpe.rededor.utils.LABELS;

@RestController
public class PessoaController {

    @GetMapping(value = "/pessoa/{pessoaCPF}")
    public PessoaDTO getPessoaById(@PathVariable String pessoaCPF) throws CustomException {
        if(pessoaCPF == null || pessoaCPF.isBlank()){
            throw new CustomException(LABELS.getLabel("PESSOA_CONTROLLER_CPF_INVALIDO"));
        }
        PessoaDTO pessoa = new PessoaDTO("Pessoa de exemplo", "00000000000");
        return pessoa;
    }
    
}
