package cl.triskeledu.pagos.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(
    name = "metodo_pago",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_metodo_pago_nombre", columnNames = "nombre")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MetodoPago {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "nombre", nullable = false, length = 50, unique = true)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false, length = 20)
    private TipoMetodoPago tipo;

    @Column(name = "comision", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal comision = BigDecimal.ZERO;

    @Column(name = "activo", nullable = false)
    @Builder.Default
    private Boolean activo = true;

    public enum TipoMetodoPago {
        tarjeta, transferencia, efectivo, wallet
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof MetodoPago)) return false;
        MetodoPago that = (MetodoPago) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
