package cl.triskeledu.ofertas.model;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "regla")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Regla {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_oferta", referencedColumnName = "codigo_oferta", nullable = false)
    private Oferta oferta;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sku", referencedColumnName = "sku", nullable = false)
    private ProductoProy producto;

    @Column(name = "precio_minimo", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal precioMinimo = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_regla", nullable = false, length = 20)
    @Builder.Default
    private TipoRegla tipoRegla = TipoRegla.directo;

    public enum TipoRegla {
        directo, condicional
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Regla)) return false;
        Regla that = (Regla) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
