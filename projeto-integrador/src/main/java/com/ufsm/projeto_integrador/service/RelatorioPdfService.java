package com.ufsm.projeto_integrador.service;

import com.lowagie.text.DocumentException;
import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.lowagie.text.pdf.draw.LineSeparator;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioGeralResponse;
import com.ufsm.projeto_integrador.domain.dto.relatorio.RelatorioPropriedadeResponse;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@Service
public class RelatorioPdfService {

    private static final DateTimeFormatter DATA_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final Color COR_PRIMARIA = new Color(0, 174, 86);
    private static final Color COR_CABECALHO = new Color(240, 240, 240);

    private static final Font FONTE_TITULO = new Font(Font.HELVETICA, 20, Font.BOLD, Color.WHITE);
    private static final Font FONTE_SUBTITULO = new Font(Font.HELVETICA, 13, Font.BOLD, COR_PRIMARIA);
    private static final Font FONTE_NORMAL = new Font(Font.HELVETICA, 10, Font.NORMAL, Color.DARK_GRAY);
    private static final Font FONTE_BOLD = new Font(Font.HELVETICA, 10, Font.BOLD, Color.DARK_GRAY);
    private static final Font FONTE_CABECALHO_TAB = new Font(Font.HELVETICA, 9, Font.BOLD, Color.DARK_GRAY);
    private static final Font FONTE_CELULA = new Font(Font.HELVETICA, 9, Font.NORMAL, Color.DARK_GRAY);

    public byte[] gerarRelatorioGeral(RelatorioGeralResponse data) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document doc = new Document(PageSize.A4, 36, 36, 36, 36);
            PdfWriter.getInstance(doc, out);
            doc.open();

            adicionarCabecalho(doc, "Relatorio Geral", data.inicio().format(DATA_FMT), data.fim().format(DATA_FMT));

            adicionarSecao(doc, "Visitas");
            adicionarMetrica(doc, "Total de visitas no periodo", String.valueOf(data.totalVisitas()));
            adicionarMapaTabela(doc, "Por status", data.visitasPorStatus());
            adicionarMapaTabela(doc, "Por tipo", data.visitasPorTipo());

            adicionarSecao(doc, "Diagnosticos");
            adicionarMetrica(doc, "Total de diagnosticos", String.valueOf(data.totalDiagnosticos()));
            adicionarMapaTabela(doc, "Por categoria", data.diagnosticosPorCategoria());
            adicionarMapaTabela(doc, "Por criticidade", data.diagnosticosPorCriticidade());

            adicionarSecao(doc, "Encaminhamentos");
            adicionarMetrica(doc, "Total de encaminhamentos", String.valueOf(data.totalEncaminhamentos()));
            adicionarMapaTabela(doc, "Por status", data.encaminhamentosPorStatus());
            if (data.encaminhadosComPrazo() > 0) {
                long pct = Math.round(data.encaminhadosConcluidosNoPrazo() * 100.0 / data.encaminhadosComPrazo());
                adicionarMetrica(doc, "Concluidos no prazo", data.encaminhadosConcluidosNoPrazo() + " de " + data.encaminhadosComPrazo() + " (" + pct + "%)");
            }

            adicionarSecao(doc, "Rankings");
            adicionarRankingTabela(doc, "Top 5 — Propriedades mais visitadas", data.topPropriedadesVisitadas(), "Visitas");
            adicionarRankingTabela(doc, "Top 5 — Propriedades com mais diagnosticos criticos/altos", data.topPropriedadesDiagnosticos(), "Diagnosticos");
            adicionarRankingTabela(doc, "Visitas concluidas por tecnico", data.visitasPorTecnico(), "Concluidas");

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new IllegalStateException("Erro ao gerar PDF do relatorio geral", e);
        }
    }

    public byte[] gerarRelatorioPropriedade(RelatorioPropriedadeResponse data) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document doc = new Document(PageSize.A4, 36, 36, 36, 36);
            PdfWriter.getInstance(doc, out);
            doc.open();

            adicionarCabecalho(doc, "Relatorio — " + data.propriedadeNome(), data.inicio().format(DATA_FMT), data.fim().format(DATA_FMT));

            adicionarSecao(doc, "Informacoes da Propriedade");
            adicionarMetrica(doc, "Proprietario", data.nomeProprietario());
            adicionarMetrica(doc, "Municipio", data.municipio());
            if (data.tipoProducao() != null) adicionarMetrica(doc, "Tipo de producao", data.tipoProducao());

            adicionarSecao(doc, "Visitas (" + data.totalVisitas() + " no periodo)");
            adicionarMapaTabela(doc, "Por status", data.visitasPorStatus());
            adicionarMapaTabela(doc, "Por tipo", data.visitasPorTipo());
            if (!data.visitas().isEmpty()) {
                adicionarVisitasTabela(doc, data.visitas());
            }

            adicionarSecao(doc, "Diagnosticos (" + data.totalDiagnosticos() + " no periodo)");
            adicionarMapaTabela(doc, "Por categoria", data.diagnosticosPorCategoria());
            adicionarMapaTabela(doc, "Por criticidade", data.diagnosticosPorCriticidade());
            if (!data.diagnosticos().isEmpty()) {
                adicionarDiagnosticosTabela(doc, data.diagnosticos());
            }

            adicionarSecao(doc, "Encaminhamentos (" + data.totalEncaminhamentos() + " no periodo)");
            adicionarMapaTabela(doc, "Por status", data.encaminhamentosPorStatus());
            if (!data.encaminhamentos().isEmpty()) {
                adicionarEncaminhamentosTabela(doc, data.encaminhamentos());
            }

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new IllegalStateException("Erro ao gerar PDF do relatorio de propriedade", e);
        }
    }

    private void adicionarCabecalho(Document doc, String titulo, String inicio, String fim) throws DocumentException {
        PdfPTable header = new PdfPTable(1);
        header.setWidthPercentage(100);
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(COR_PRIMARIA);
        cell.setPadding(16);
        cell.setBorder(Rectangle.NO_BORDER);
        Paragraph p = new Paragraph(titulo + "\n", FONTE_TITULO);
        p.add(new Phrase("Periodo: " + inicio + " a " + fim, new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(200, 255, 220))));
        cell.addElement(p);
        header.addCell(cell);
        doc.add(header);
        doc.add(Chunk.NEWLINE);
    }

    private void adicionarSecao(Document doc, String titulo) throws DocumentException {
        doc.add(Chunk.NEWLINE);
        Paragraph p = new Paragraph(titulo, FONTE_SUBTITULO);
        p.setSpacingAfter(6);
        doc.add(p);
        doc.add(new LineSeparator(1, 100, COR_PRIMARIA, Element.ALIGN_LEFT, 0));
        doc.add(Chunk.NEWLINE);
    }

    private void adicionarMetrica(Document doc, String label, String valor) throws DocumentException {
        Paragraph p = new Paragraph();
        p.add(new Phrase(label + ": ", FONTE_BOLD));
        p.add(new Phrase(valor != null ? valor : "—", FONTE_NORMAL));
        p.setSpacingAfter(4);
        doc.add(p);
    }

    private void adicionarMapaTabela(Document doc, String label, Map<String, Long> mapa) throws DocumentException {
        if (mapa == null || mapa.isEmpty()) return;

        Paragraph titulo = new Paragraph(label, new Font(Font.HELVETICA, 9, Font.BOLD, Color.GRAY));
        titulo.setSpacingBefore(6);
        titulo.setSpacingAfter(4);
        doc.add(titulo);

        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(60);
        table.setHorizontalAlignment(Element.ALIGN_LEFT);
        table.setWidths(new float[]{3, 1});

        mapa.forEach((k, v) -> {
            PdfPCell c1 = celula(humanize(k), FONTE_CELULA, false);
            PdfPCell c2 = celula(String.valueOf(v), FONTE_CELULA, false);
            c2.setHorizontalAlignment(Element.ALIGN_RIGHT);
            table.addCell(c1);
            table.addCell(c2);
        });

        doc.add(table);
    }

    private void adicionarRankingTabela(Document doc, String label, java.util.List<RelatorioGeralResponse.RankingItem> items, String colTotal) throws DocumentException {
        if (items == null || items.isEmpty()) return;

        Paragraph titulo = new Paragraph(label, new Font(Font.HELVETICA, 9, Font.BOLD, Color.GRAY));
        titulo.setSpacingBefore(6);
        titulo.setSpacingAfter(4);
        doc.add(titulo);

        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(80);
        table.setHorizontalAlignment(Element.ALIGN_LEFT);
        table.setWidths(new float[]{4, 1});

        cabecalhoTabela(table, "Nome", colTotal);
        for (var item : items) {
            table.addCell(celula(item.nome(), FONTE_CELULA, false));
            PdfPCell c = celula(String.valueOf(item.total()), FONTE_CELULA, false);
            c.setHorizontalAlignment(Element.ALIGN_RIGHT);
            table.addCell(c);
        }
        doc.add(table);
    }

    private void adicionarVisitasTabela(Document doc, java.util.List<RelatorioPropriedadeResponse.VisitaItem> visitas) throws DocumentException {
        Paragraph titulo = new Paragraph("Historico de visitas", new Font(Font.HELVETICA, 9, Font.BOLD, Color.GRAY));
        titulo.setSpacingBefore(6);
        titulo.setSpacingAfter(4);
        doc.add(titulo);

        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{2, 2, 2, 2});
        cabecalhoTabela(table, "Data", "Tecnico", "Tipo", "Status");

        for (var v : visitas) {
            table.addCell(celula(v.data().format(DATA_FMT), FONTE_CELULA, false));
            table.addCell(celula(v.tecnico(), FONTE_CELULA, false));
            table.addCell(celula(humanize(v.tipo()), FONTE_CELULA, false));
            table.addCell(celula(humanize(v.status()), FONTE_CELULA, false));
        }
        doc.add(table);
    }

    private void adicionarDiagnosticosTabela(Document doc, java.util.List<RelatorioPropriedadeResponse.DiagnosticoItem> diags) throws DocumentException {
        Paragraph titulo = new Paragraph("Lista de diagnosticos", new Font(Font.HELVETICA, 9, Font.BOLD, Color.GRAY));
        titulo.setSpacingBefore(6);
        titulo.setSpacingAfter(4);
        doc.add(titulo);

        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{2, 1.5f, 3});
        cabecalhoTabela(table, "Categoria", "Criticidade", "Observacoes");

        for (var d : diags) {
            table.addCell(celula(d.categoria(), FONTE_CELULA, false));
            table.addCell(celula(humanize(d.criticidade()), FONTE_CELULA, false));
            table.addCell(celula(d.observacoes() != null ? d.observacoes() : "—", FONTE_CELULA, false));
        }
        doc.add(table);
    }

    private void adicionarEncaminhamentosTabela(Document doc, java.util.List<RelatorioPropriedadeResponse.EncaminhamentoItem> encs) throws DocumentException {
        Paragraph titulo = new Paragraph("Lista de encaminhamentos", new Font(Font.HELVETICA, 9, Font.BOLD, Color.GRAY));
        titulo.setSpacingBefore(6);
        titulo.setSpacingAfter(4);
        doc.add(titulo);

        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{3, 1.5f, 1.5f, 1.5f});
        cabecalhoTabela(table, "Acao", "Responsavel", "Prazo", "Status");

        for (var e : encs) {
            table.addCell(celula(e.acaoRealizada(), FONTE_CELULA, false));
            table.addCell(celula(e.responsavel() != null ? e.responsavel() : "—", FONTE_CELULA, false));
            table.addCell(celula(e.prazo() != null ? e.prazo().format(DATA_FMT) : "—", FONTE_CELULA, false));
            table.addCell(celula(humanize(e.status()), FONTE_CELULA, false));
        }
        doc.add(table);
    }

    private void cabecalhoTabela(PdfPTable table, String... colunas) {
        for (String col : colunas) {
            table.addCell(celula(col, FONTE_CABECALHO_TAB, true));
        }
    }

    private PdfPCell celula(String texto, Font fonte, boolean cabecalho) {
        PdfPCell cell = new PdfPCell(new Phrase(texto != null ? texto : "—", fonte));
        cell.setPadding(5);
        cell.setBorderColor(new Color(220, 220, 220));
        if (cabecalho) cell.setBackgroundColor(COR_CABECALHO);
        return cell;
    }

    private String humanize(String value) {
        if (value == null || value.isBlank()) return "—";
        return value.charAt(0) + value.substring(1).toLowerCase().replace('_', ' ');
    }
}
