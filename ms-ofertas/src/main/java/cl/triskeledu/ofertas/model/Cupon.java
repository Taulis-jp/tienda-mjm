package cl.triskeledu.ofertas.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "cupon",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_cupon_codigo", columnNames = "codigo_cupon")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Cupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "codigo_cupon", nullable = false, length = 50, unique = true)
    private String codigoCupon;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_oferta", referencedColumnName = "codigo_oferta", nullable = false)
    private Oferta oferta;

    @Column(name = "usos_max", nullable = false)
    @Builder.Default
    private Integer usosMax = 1;

    @Column(name = "usos_actuales", nullable = false)
    @Builder.Default
    private Integer usosActuales = 0;

    @Transient
    public boolean isAgotado() {
        return usosActuales >= usosMax;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Cupon)) return false;
        Cupon that = (Cupon) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
