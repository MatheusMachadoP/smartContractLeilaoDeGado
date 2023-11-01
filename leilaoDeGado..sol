// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract LeilaoDeGado {
    address public leiloeiro;
    string public nomeAtivo;
    uint public precoInicial;
    uint public duracaoRodada;
    uint public numeroRodadas;
    uint private horarioInicio;
    uint private horarioFim;
    bool public leilaoAberto;
    uint public maiorLance;
    address public licitanteVencedor;
    uint public rodada;
    address private semLancesNaRodada = address(0);
    string public chavePublicaLeiloeiro;
    string public data;
    string public chavePublicaVencedor;

    struct Licitante {
        address conta;
        string nome;
        string cpf;
        string chavePublica;
    }

    Licitante[] public licitantes;

    event LeilaoIniciado(
        string ativo,
        uint precoinicial,
        uint duracaoRodada,
        uint numeroRodadas
    );

    event NovoLance(address indexed licitante, uint valor);

    event LeilaoEncerrado(
        address licitanteVencedor,
        uint valor,
        string nomeVencedor,
        string cpfVencedor,
        string chavePublicaVencedor
    );

    event NovaTransacao(
        address remetente,
        uint valor,
        uint gasLimit,
        uint gasUsado,
        uint bloco
    );

    constructor(
        string memory _nomeAtivo,
        uint _precoInicial,
        uint _duracaoRodada,
        uint _numeroRodadas,
        string memory _chaveLeiloeiro,
        string memory _data
    ) {
        leiloeiro = msg.sender;
        nomeAtivo = _nomeAtivo;
        precoInicial = _precoInicial;
        duracaoRodada = _duracaoRodada;
        numeroRodadas = _numeroRodadas;
        leilaoAberto = false;
        maiorLance = 0;
        licitanteVencedor = address(0);
        rodada = 1;
        chavePublicaLeiloeiro = _chaveLeiloeiro;
        data = _data;

        Licitante memory primeiroLicitante = Licitante({
            conta: msg.sender,
            nome: "Leiloeiro",
            cpf: "",
            chavePublica: _chaveLeiloeiro
        });
        licitantes.push(primeiroLicitante);
    }

    modifier somenteLeiloeiro() {
        require(msg.sender == leiloeiro);
        _;
    }

    function iniciarLeilao() public somenteLeiloeiro {
        require(!leilaoAberto, "Leilao nao foi iniciado.");
        horarioInicio = block.timestamp;
        horarioFim = horarioInicio + (duracaoRodada * numeroRodadas);
        leilaoAberto = true;
        emit LeilaoIniciado(
            nomeAtivo,
            precoInicial,
            duracaoRodada,
            numeroRodadas
        );
    }

function darLance(uint256 _valor, string memory _nome, string memory _cpf, string memory _chavePublica) public {
    require(leilaoAberto, "O leilao esta fechado.");
    require(block.timestamp <= horarioFim, "O leilao desta rodada ja encerrou.");
    require(_valor > maiorLance, "O lance nao e maior que o lance atual");
    require(_valor >= precoInicial, "O lance nao atende o preco minimo");

    maiorLance = _valor;
    licitanteVencedor = msg.sender;

    Licitante memory novoLicitante = Licitante({
        conta: msg.sender,
        nome: _nome,
        cpf: _cpf,
        chavePublica: _chavePublica
    });

    // Atualize a chave pública do vencedor
    chavePublicaVencedor = _chavePublica;

    licitantes.push(novoLicitante);
    emit NovoLance(msg.sender, _valor);
}

function verificarEncerramentoRodada() public {
    require(block.timestamp > horarioFim, "O tempo ainda nao acabou");

    if (licitanteVencedor == semLancesNaRodada) {
        leilaoAberto = false;
    } else {
        string memory nomeVencedor;
        string memory cpfVencedor;
        string memory enderecoDoVencedor;

        for (uint i = 0; i < licitantes.length; i++) {
            if (licitantes[i].conta == licitanteVencedor) {
                nomeVencedor = licitantes[i].nome;
                cpfVencedor = licitantes[i].cpf;
                enderecoDoVencedor = licitantes[i].chavePublica;
                break;
            }
        }

        emit LeilaoEncerrado(
            licitanteVencedor,
            maiorLance,
            nomeVencedor,
            cpfVencedor,
            enderecoDoVencedor
        );
    }
}


function pagamentoParaLeiloeiro(uint valorDoPagamento) public {
    require(!leilaoAberto, "O leilao ainda esta aberto.");
    require(msg.sender == licitanteVencedor,"Apenas o licitante vencedor pode realizar o pagamento.");
    require(valorDoPagamento == maiorLance,"O valor do pagamento deve ser igual ao maior lance.");

    // Agora o licitante vencedor realizar o pagamento manualmente
    address payable leiloeiroPayable = payable(leiloeiro);
    leiloeiroPayable.transfer(valorDoPagamento);

    leilaoAberto = false;
}


    function finalizarLeilao() public somenteLeiloeiro {
        require(leilaoAberto, "O leilao esta fechado ou nao foi iniciado.");

        leilaoAberto = false;
    }

    function enderecoLeilao() public view returns (address) {
        return address(this); // Retornando o endereco
    }

    function obterData() public view returns (string memory) {
        return data;
    }

    function tempoRestanteParaEncerrarLeilao() public view returns (uint) {
        require(leilaoAberto, "O leilAo esta fechado ou nao foi iniciado.");

        if (block.timestamp >= horarioFim) {
            return 0; // O leilão já encerrou
        } else {
            return horarioFim - block.timestamp;
        }
    }
}

contract LeilaoDeGadoHash {
    bytes32 private codigoHash;
    address public leilaoDeGadoAddress;

    constructor(address _leilaoDeGadoAddress) {
        leilaoDeGadoAddress = _leilaoDeGadoAddress;
        codigoHash = keccak256(
            abi.encodePacked(type(LeilaoDeGado).runtimeCode)
        );
    }

    function ObterHash() external view returns (bytes32) {
        return codigoHash;
    }
}
