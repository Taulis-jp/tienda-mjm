package cl.triskeledu.ofertas.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Entity
@Table(
    name = "oferta",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_oferta_codigo", columnNames = "codigo_oferta")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Oferta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "codigo_oferta", nullable = false, length = 50, unique = true)
    private String codigoOferta;

    @Column(name = "descripcion", nullable = false, length = 150)
    private String descripcion;

    @Column(name = "descuento", nullable = false, precision = 10, scale = 2)
    private BigDecimal descuento;

    @Column(name = "activa", nullable = false)
    @Builder.Default
    private Boolean activa = true;

    @OneToMany(mappedBy = "oferta", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Cupon> cupones;

    @OneToMany(mappedBy = "oferta", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Regla> reglas;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Oferta)) return false;
        Oferta that = (Oferta) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
